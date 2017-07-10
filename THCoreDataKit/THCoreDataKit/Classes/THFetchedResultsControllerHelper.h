//
//  THFetchedResultsControllerHelper.h
//  TaphouseKit
//
//  Created by Jared Sorge on 7/26/14.
//  Copyright (c) 2014 Taphouse Software. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;
@import CoreData;

/**
 *  This notification will fire when the Fetched Results Controller updates its content. The notification's userInfo dictionary will have 2 keys, for inserted and deleted index paths. The corresponding values will be an array of the affected index paths.
 */
extern NSString *const FetchedResultsControllerUpdatedNotification;
extern NSString *const FetchedResultsControllerInsertedIndexPathsKey;
extern NSString *const FetchedResultsControllerDeletedIndexPathsKey;

@interface THFetchedResultsControllerHelper : NSObject <NSFetchedResultsControllerDelegate>

/**
 *  Controls the CRUD operations of a table view backed by an NSFetchedResultsController. Mostly a boilerplate helper.
 *
 *  @param tableView The UITableView to be assigned.
 *  @param insertAnimation The animation used to insert rows. The default is fade (since that is 0 on the enum)
 *  @param deleteAnimation The animation used to delete rows. The default is fade (since that is 0 on the enum)
 *
 *  @return self
 */
- (instancetype)initWithTableView:(UITableView *)tableView insertRowAnimation:(UITableViewRowAnimation)insertAnimation deleteRowAnimation:(UITableViewRowAnimation)deleteAnimation;

/**
 *  Controls the CRUD operations of a table view backed by an NSFetchedResultsController. Mostly a boilerplate helper. To override the animations for row insertions and deletions, use initWithTableView:insertRowAmimation:deleteRowAnimation. This instance will use UITableViewRowAnimationAutomatic.
 *
 *  @param tableView The UITableView to be assigned.
 *
 *  @return self
 */
- (instancetype)initWithTableView:(UITableView *)tableView;

/**
 *  Controls the CRUD operations of a collection view backed by an NSFetchedResultsController. Mostly a boilerplate helper.
 *
 *  @param collectionView The UICollectionView to be assigned.
 *
 *  @return self
 */
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;

@end
