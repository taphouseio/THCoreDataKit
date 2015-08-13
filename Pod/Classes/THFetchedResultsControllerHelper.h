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

@interface THFetchedResultsControllerHelper : NSObject <NSFetchedResultsControllerDelegate>

/**
 *  Determines the animation to be run when a row or section is deleted. If this is nil, will fall back to UITableViewRowAnimationAutomatic.
 */
@property (nonatomic) UITableViewRowAnimation deleteRowAnimation;

/**
 *  Determines the animation to be run when a row or section is inserted. If this is nil, will fall back to UITableViewRowAnimationAutomatic.
 */
@property (nonatomic) UITableViewRowAnimation insertRowAnimation;

/**
 *  Controls the CRUD operations of a table view backed by an NSFetchedResultsController. Mostly a boilerplate helper.
 *
 *  @param tableView The UITableView to be assigned.
 *
 *  @return self
 */
- (instancetype)initWithTableView:(UITableView *)tableView;

/**
 *  Controls the CRUD operations of a collection view backed by an NSFetchedResultsController. Mostly a boilerplate helper.
 *
 *  @param tableView The UICollectionView to be assigned.
 *
 *  @return self
 */
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;
@end
