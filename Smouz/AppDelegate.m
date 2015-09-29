//  Smouz
//  Created by Charles Parnot on 8/10/14.
//  Licensed under the terms of the modified BSD License, as specified in the file 'LICENSE-BSD.txt' included with this distribution


#import "AppDelegate.h"
#import "SmouzView.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet SmouzView *graph;
@property (copy) NSArray *data;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"ShouldConstrainBounds": @(YES), @"CurveTightness": @(3.0)}];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{

}


- (void)awakeFromNib
{
    self.data = @[
                  @{ @"x" : @(  0.0), @"y" : @(10.0) }.mutableCopy,
                  @{ @"x" : @( 20.0), @"y" : @(20.0) }.mutableCopy,
                  @{ @"x" : @( 40.0), @"y" : @(20.0) }.mutableCopy,
                  @{ @"x" : @( 45.0), @"y" : @( 5.0) }.mutableCopy,
                  @{ @"x" : @( 50.0), @"y" : @(90.0) }.mutableCopy,
                  @{ @"x" : @( 70.0), @"y" : @(50.0) }.mutableCopy,
                  @{ @"x" : @( 72.0), @"y" : @(80.0) }.mutableCopy,
                  @{ @"x" : @( 75.0), @"y" : @(35.0) }.mutableCopy,
                  @{ @"x" : @( 90.0), @"y" : @( 0.0) }.mutableCopy,
                  @{ @"x" : @(100.0), @"y" : @(90.0) }.mutableCopy,
                  ];
    [self.tableView reloadData];
    self.graph.data = self.data;
    [self.graph setNeedsDisplay:YES];
}


#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.data.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return self.data[row][tableColumn.identifier];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSMutableDictionary *coordinates = self.data[row];
    coordinates[tableColumn.identifier] = object;
    self.graph.data = self.data;
    [self.graph setNeedsDisplay:YES];
}

@end
