//
//  THFetchedResultsControllerHelper.m
//  TaphouseKit
//
//  Created by Jared Sorge on 7/26/14.
//  Copyright (c) 2014 Taphouse Software. All rights reserved.
//

#import "THFetchedResultsControllerHelper.h"

NSString *const FetchedResultsControllerUpdatedNotification = @"FetchedResultsControllerUpdatedNotification";
NSString *const FetchedResultsControllerInsertedIndexPathsKey = @"insertedIndexPaths";
NSString *const FetchedResultsControllerDeletedIndexPathsKey = @"deletedIndexPaths";


@interface THFetchedResultsControllerHelper ()
@property (nonatomic, weak)UITableView *tableView;
@property (nonatomic, weak)UICollectionView *collectionView;
@property (nonatomic, strong)NSMutableArray *collectionViewObjectChanges;
@property (nonatomic) UITableViewRowAnimation insertRowAnimation;
@property (nonatomic) UITableViewRowAnimation deleteRowAnimation;

@property (nonatomic, strong) NSMutableArray *insertedIndexPaths;
@property (nonatomic, strong) NSMutableArray *deletedIndexPaths;

@property (nonatomic, strong) NSMutableArray *insertedSections;
@property (nonatomic, strong) NSMutableArray *deletedSections;
@property (nonatomic, strong) NSMutableArray *updatedObjects;
@property (nonatomic, strong) NSMutableArray *movedObjects;
@property (nonatomic, strong) NSMutableArray *itemSectionCount;
@end

@implementation THFetchedResultsControllerHelper
#pragma mark - API
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self) {
        self.collectionView = collectionView;
    }
    return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView insertRowAnimation:(UITableViewRowAnimation)insertAnimation deleteRowAnimation:(UITableViewRowAnimation)deleteAnimation
{
    self = [super init];
    if (self) {
        self.tableView = tableView;
        self.insertRowAnimation = insertAnimation;
        self.deleteRowAnimation = deleteAnimation;
    }
    return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView
{
    return [self initWithTableView:tableView
                insertRowAnimation:UITableViewRowAnimationAutomatic
                deleteRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    self.insertedIndexPaths = [NSMutableArray array];
    self.deletedIndexPaths = [NSMutableArray array];
    
    if (self.tableView) {
        self.insertedSections = [NSMutableArray array];
        self.deletedSections = [NSMutableArray array];
        self.movedObjects = [NSMutableArray array];
        self.updatedObjects = [NSMutableArray array];
        
        self.itemSectionCount = [NSMutableArray array];
        NSInteger sections = [self.tableView numberOfSections];
        for (int i = 0; i < sections; i++) {
            NSInteger rows = [self.tableView numberOfRowsInSection:i];
            [self.itemSectionCount addObject:@(rows)];
        }
    } else if (self.collectionView) {
        self.collectionViewObjectChanges = [NSMutableArray new];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.tableView) {
        [self replayTableChanges];
    } else if (self.collectionView) {
        if (self.collectionViewObjectChanges.count > 0) {
            [self.collectionView performBatchUpdates:^{
                for (NSDictionary *objectChange in self.collectionViewObjectChanges) {
                    [objectChange enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        
                        switch (type) {
                            case NSFetchedResultsChangeInsert:
                                [self.collectionView insertItemsAtIndexPaths:@[obj]];
                                break;
                                
                            case NSFetchedResultsChangeUpdate:
                                [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                                break;
                                
                            case NSFetchedResultsChangeDelete:
                                [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                                break;
                            
                            case NSFetchedResultsChangeMove:
                                break;
                        }
                    }];
                }
            } completion:nil];
        }
    }
    
    NSDictionary *userInfo = @{
                               FetchedResultsControllerInsertedIndexPathsKey : [self.insertedIndexPaths copy],
                               FetchedResultsControllerDeletedIndexPathsKey : [self.deletedIndexPaths copy]
                               };
    [[NSNotificationCenter defaultCenter] postNotificationName:FetchedResultsControllerUpdatedNotification
                                                        object:self
                                                      userInfo:userInfo
     ];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            if (self.tableView) {
            } else if (self.collectionView) {
                [self.collectionViewObjectChanges addObject:@{@(type): newIndexPath}];
            }
        
            [self.insertedIndexPaths addObject:newIndexPath];
            break;
            
        case NSFetchedResultsChangeUpdate:
            if (self.tableView) {
                [self.updatedObjects addObject:indexPath];
            } else if (self.collectionView) {
                [self.collectionViewObjectChanges addObject:@{@(type): indexPath}];
            }
            break;
        
        case NSFetchedResultsChangeDelete:
            if (self.tableView) {
            } else if (self.collectionView) {
                [self.collectionViewObjectChanges addObject:@{@(type): indexPath}];
            }
        
            [self.deletedIndexPaths addObject:indexPath];
            break;
        
        case NSFetchedResultsChangeMove:
            if (self.tableView) {
                [self.movedObjects addObject:@{@"oldIndex": indexPath, @"newIndex": newIndexPath}];
            } else if (self.collectionView) {
                [self.collectionViewObjectChanges addObject:@{@(type): @[indexPath, newIndexPath]}];
            }
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            if (self.tableView) {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
                [self.insertedSections addObject:indexSet];
            }
            break;
        }
            
        case NSFetchedResultsChangeDelete: {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
            [self.deletedSections addObject:indexSet];
            break;
        }
            
        default: {
            break;
        }
    }
}

#pragma mark - Private
- (void)replayTableChanges
{
    /*
     The batches need to be grouped because you can't insert rows into newly inserted sections(?!)
     
     Only replay the first stage of changes if they exist, otherwise if the data source has changed the number of rows in a section but not modified the number of sections in the table you don't want to begin/end updating the table view without making it compliant to the data source.
    */
    if (self.deletedSections.count > 0 || self.insertedSections.count > 0 || self.deletedIndexPaths.count > 0) {
        [self replayTableStageOneChanges];
    }
    
    [self replayTableStageTwoChanges];
}

- (void)replayTableStageOneChanges
{
    [self.tableView beginUpdates];
    
    /*
     Deal with deleting and inserting sections first.
     
     These become the equivalent of moving rows around but done in a way that won't cause a "serious application error."
     */
    for (NSIndexSet *section in self.deletedSections) {
        if (![self.insertedSections containsObject:section]) {
            [self.tableView deleteSections:section withRowAnimation:self.deleteRowAnimation];
            
            for (NSDictionary <NSString *, NSIndexPath *> *movedObject in self.movedObjects) {
                NSIndexPath *oldIndexPath = movedObject[@"oldIndex"];
                if ([section containsIndex:oldIndexPath.section]) {
                    NSIndexPath *newIndexPath = movedObject[@"newIndex"];
                    [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:self.insertRowAnimation];
                    [self.movedObjects removeObject:movedObject];
                }
            }
        }
    }
    
    for (NSIndexSet *section in self.insertedSections) {
        if (![self.deletedSections containsObject:section]) {
            [self.tableView insertSections:section withRowAnimation:self.insertRowAnimation];
            
            for (NSDictionary <NSString *, NSIndexPath *> *movedObject in self.movedObjects) {
                NSIndexPath *newIndexPath = movedObject[@"newIndex"];
                if ([section containsIndex:newIndexPath.section]) {
                    NSIndexPath *oldIndexPath = movedObject[@"oldIndex"];
                    [self.tableView deleteRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.movedObjects removeObject:movedObject];
                    [self.updatedObjects removeObject:oldIndexPath];
                }
            }
            
            for (NSIndexPath *insertedIndexPath in self.insertedIndexPaths) {
                if ([section containsIndex:insertedIndexPath.section]) {
                    [self.insertedIndexPaths removeObject:insertedIndexPath];
                }
            }
        }
    }
    for (NSIndexSet *section in self.insertedSections) {
        [self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    if (self.deletedIndexPaths.count > 0) {
        [self.tableView deleteRowsAtIndexPaths:self.deletedIndexPaths withRowAnimation:self.deleteRowAnimation];
    }
    
    [self.tableView endUpdates];
}

- (void)replayTableStageTwoChanges
{
    [self.tableView beginUpdates];
    
    if (self.insertedIndexPaths.count > 0) {
        [self.tableView insertRowsAtIndexPaths:self.insertedIndexPaths withRowAnimation:self.insertRowAnimation];
    }
    
    for (NSDictionary <NSString *, NSIndexPath *> *movedObject in self.movedObjects) {
        NSIndexPath *oldIndex = movedObject[@"oldIndex"];
        NSIndexPath *newIndex = movedObject[@"newIndex"];
        
        if (oldIndex == newIndex) {
            continue;
        }
        
        NSIndexSet *oldIndexSet = [NSIndexSet indexSetWithIndex:oldIndex.section];
        NSIndexSet *newIndexSet = [NSIndexSet indexSetWithIndex:newIndex.section];
        BOOL sectionDeleted = [self.deletedSections containsObject:oldIndexSet] || [self.deletedSections containsObject:newIndexSet];
        if (!sectionDeleted) {
            NSNumber *oldSectionRows = self.itemSectionCount[oldIndex.section];
            oldSectionRows = @(([oldSectionRows integerValue] - 1));
            
            if ([oldSectionRows integerValue] == 0) {
                [self.tableView deleteSections:oldIndexSet withRowAnimation:self.deleteRowAnimation];
            }
            
            [self.tableView moveRowAtIndexPath:oldIndex toIndexPath:newIndex];
        }
    }
    
    for (NSIndexPath *updatedPath in self.updatedObjects) {
        [self.tableView reloadRowsAtIndexPaths:@[updatedPath] withRowAnimation:self.insertRowAnimation];
    }
    
    [self.tableView endUpdates];
}

@end
