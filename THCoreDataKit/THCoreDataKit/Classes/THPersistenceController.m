//
//  THPersistenceController.m
//  Pods
//
//  Created by Jared Sorge on 3/31/15.
//  Copyright (c) 2015 Taphouse Software. All rights reserved.
//

#import "THPersistenceController.h"
@import CoreData;

@interface THPersistenceController ()
@property (nonatomic, readwrite) NSManagedObjectContext *masterContext;
@property (nonatomic, strong) NSManagedObjectContext *privateContext;
@property (nonatomic, copy) InitCallbackBlock callbackBlock;
@property (nonatomic, strong) NSMutableArray *vendedBackgroundContexts;
@end

static THPersistenceController *_globalPersistenceController = nil;

@implementation THPersistenceController
#pragma mark - API
+ (instancetype)createGlobalPersistenceControllerWithModelName:(NSString *)modelName storeURL:(NSURL *)storeURL storeType:(NSString *)storeType callback:(InitCallbackBlock)callback;
{
    if (_globalPersistenceController != nil) {
        return [THPersistenceController globalPersistenceController];
    }
    
    _globalPersistenceController = [[THPersistenceController alloc] initWithStoreType:storeType
                                                                            modelName:modelName
                                                                             storeURL:storeURL
                                                                             callback:callback];
    return _globalPersistenceController;
}

+ (instancetype)globalPersistenceController
{
    NSAssert(_globalPersistenceController != nil, @"The global persistence controller must not be nil before usage.");
    return _globalPersistenceController;
}

- (void)save
{
    if (![self.privateContext hasChanges] && ![self.masterContext hasChanges] && ![self vendedContextsHaveChanges]) {
        return;
    }
    
    for (NSManagedObjectContext *context in self.vendedBackgroundContexts) {
        if ([context hasChanges]) {
            NSError *blockError = nil;
            [context save:&blockError];
            NSAssert(blockError == nil, @"Failed to save vended background context: %@\n%@", blockError.localizedDescription, blockError.userInfo);
        }
    }
    
    __weak typeof(self) weakSelf = self;
    [self.masterContext performBlockAndWait:^{
        NSError *saveError = nil;
        if (weakSelf.masterContext.hasChanges) {
            [weakSelf.masterContext save:&saveError];
            NSAssert(saveError == nil, @"Failed to save on the main thread: %@\n%@", saveError.localizedDescription, saveError.userInfo);
        }
        
        [weakSelf.privateContext performBlock:^{
            NSError *privateError = nil;
            [weakSelf.privateContext save:&privateError];
            NSAssert(privateError == nil, @"Failed to save on the private thread.", privateError.localizedDescription, privateError.userInfo);
        }];
    }];
}

- (BOOL)migrateExistingStoreToNewStoreWithURL:(NSURL *)storeURL
{
    BOOL success = NO;
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption       : @YES};
    NSError *migrateError = nil;
    
    NSPersistentStoreCoordinator *coordinator = self.privateContext.persistentStoreCoordinator;
    
    NSPersistentStore *currentStore = [[coordinator persistentStores] firstObject];
    [coordinator migratePersistentStore:currentStore
                                  toURL:storeURL
                                options:options
                               withType:NSSQLiteStoreType
                                  error:&migrateError];
    
    if (migrateError) {
        NSLog(@"Error migrating the store.\n%@", migrateError.localizedDescription);
    }
    else {
        success = YES;
    }
    
    return success;
}

- (NSManagedObjectContext *)createBackgroundContext
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = self.masterContext;
    
    [self.vendedBackgroundContexts addObject:context];
    
    return context;
}

#pragma mark - Properties
- (NSMutableArray *)vendedBackgroundContexts
{
    if (!_vendedBackgroundContexts) {
        _vendedBackgroundContexts = [NSMutableArray array];
    }
    return _vendedBackgroundContexts;
}

#pragma mark - Private
/**
 *  Instantiates the controller. Will be called-back on the main thread once completed
 *
 *  @param callback     What should happen after instantiation
 *  @param storeType    The type of the data store. If this is nil, then it will default to NSSQLiteStoreType. Use this value if wanting a memory store type (NSInMemoryStoreType) which is useful for testing.
 *
 *  @return Ready to roll PersistenceController
 */
- (instancetype)initWithStoreType:(NSString *)storeType modelName:(NSString *)modelName storeURL:(NSURL *)storeURL callback:(InitCallbackBlock)callback
{
    self = [super init];
    
    if (self) {
        self.callbackBlock = callback;
        [self setupCoreDataWithStoreType:storeType modelName:modelName storeURL:storeURL];
    }
    
    return self;
}

- (void)setupCoreDataWithStoreType:(NSString *)storeType modelName:(NSString *)modelName storeURL:(NSURL *)storeURL
{
    if (self.masterContext) {
        return;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
    NSManagedObjectModel *objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(objectModel != nil, @"The managed object model failed to load.");
    
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:objectModel];
    NSAssert(psc != nil, @"Failed to load the persistent store coordinator.");
    
    self.privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.privateContext.persistentStoreCoordinator = psc;
    self.masterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.masterContext.parentContext = self.privateContext;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSPersistentStoreCoordinator *coordinator = self.privateContext.persistentStoreCoordinator;
        NSError *error;
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
                                  NSInferMappingModelAutomaticallyOption       : @YES};
        
        if (![coordinator addPersistentStoreWithType:storeType != nil ? storeType : NSSQLiteStoreType
                                       configuration:nil
                                                 URL:storeURL
                                             options:options
                                               error:&error]) {
            //TODO: Handle error better
            NSLog(@"Failed creating persistent store with error: %@\n%@", error.localizedDescription, error.userInfo);
            abort();
        }
        
        if (!self.callbackBlock) {
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.callbackBlock(self.masterContext);
        }];
    });
}

- (BOOL)vendedContextsHaveChanges
{
    BOOL changes = NO;
    
    for (NSManagedObjectContext *context in self.vendedBackgroundContexts) {
        if ([context hasChanges]) {
            changes = YES;
            break;
        }
    }
    
    return changes;
}
@end
