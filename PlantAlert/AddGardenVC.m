//
//  AddGardenVC.m
//  PlantAlert
//
//  Created by Casey R White on 11/18/14.
//  Copyright (c) 2014 Code Fellows. All rights reserved.
//

#import "AddGardenVC.h"
#import "PAConstants.h"
#import "CityAutocompleteCell.h"
#import <CoreData/CoreData.h>
#import "CoreDataSeeder.h"
#import "AppDelegate.h"
#import "City.h"

@interface AddGardenVC () <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSArray *cities;
@property (strong, nonatomic) NSArray *searchResults;

@property (strong, nonatomic) UIBarButtonItem *customBackButtonItem;
@end

@implementation AddGardenVC

-(UIBarButtonItem *)customBackButtonItem {
    if (!_customBackButtonItem) {
        UIImage *image = [UIImage imageNamed:@"leftGreen1"];
        CGRect frame = CGRectMake(0, 0, 22, 22);
        UIButton* button = [[UIButton alloc] initWithFrame:frame];
        [button setBackgroundImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(navigateBack:) forControlEvents:UIControlEventTouchDown];
        _customBackButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    
    return _customBackButtonItem;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Add a Garden";
    
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem setLeftBarButtonItem:self.customBackButtonItem];

    UINib *cityAutocompleteCellNib = [UINib nibWithNibName:kReIDCityAutocompleteCell bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:cityAutocompleteCellNib forCellReuseIdentifier:kReIDCityAutocompleteCell];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    [self fetchUnselectedCities];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    
    self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    self.searchController.searchBar.placeholder = @"Search by city";
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.searchController.searchBar.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.searchController setActive:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchUnselectedCities {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"City"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    NSError *error = nil;
    NSArray *fetchedCities = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"Error executing fetch request: %@", [error localizedDescription]);
    }
    else {
        if (fetchedCities.count == 0) {
            CoreDataSeeder *seeder = [[CoreDataSeeder alloc] initWithContext:self.managedObjectContext];
            [seeder seedCoreData];
            fetchedCities = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        }
        
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"selected == %@", [NSNumber numberWithBool:NO]];
        self.cities = [fetchedCities filteredArrayUsingPredicate:filterPredicate];
    }
}

- (IBAction)navigateBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active) {
        return self.searchResults.count;
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CityAutocompleteCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kReIDCityAutocompleteCell];
    City *city = self.searchResults[indexPath.row];
    cell.cityNameLabel.text = city.name;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    City *selectedCity = self.searchResults[indexPath.row];
    [self.searchController setActive:NO];
    
    if (self.citySelectionDelegate) {
        [self.citySelectionDelegate citySelected:selectedCity];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    [self filterSearchResultsWithSearchString:searchString];
}

- (void)filterSearchResultsWithSearchString:(NSString *)searchString {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(name BEGINSWITH[cd] %@)", searchString];
    self.searchResults = [self.cities filteredArrayUsingPredicate:predicate];
    [self.tableView reloadData];
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self.navigationItem setLeftBarButtonItem:nil];
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.navigationItem setLeftBarButtonItem:self.customBackButtonItem];
}

@end
