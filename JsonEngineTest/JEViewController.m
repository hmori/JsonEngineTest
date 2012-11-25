//
//  JEViewController.m
//  JsonEngineTest
//
//  Created by Hidetoshi Mori on 12/11/25.
//  Copyright (c) 2012年 Hidetoshi Mori. All rights reserved.
//

#import "JEViewController.h"

@interface JEViewController ()
@property (nonatomic) NSMutableArray *records;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *userTextField;
@property (weak, nonatomic) IBOutlet UITextField *msgTextField;

- (IBAction)refreshAction:(UIBarButtonItem *)sender;
- (IBAction)editAction:(UIBarButtonItem *)sender;
- (IBAction)searchAction:(UIButton *)sender;
- (IBAction)postAction:(UIButton *)sender;

- (void)requestGetUser:(NSString *)user;
- (void)requestPostUser:(NSString *)user msg:(NSString *)msg;
- (void)requestDeleteDocId:(NSString *)docId;

@end

@implementation JEViewController
@synthesize records = _records;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self requestGetUser:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _records.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    NSDictionary *rec = [_records objectAtIndex:indexPath.row];
    NSString *user = [rec objectForKey:@"user"];
    NSString *msg = [rec objectForKey:@"msg"];
    cell.textLabel.text = user;
    cell.detailTextLabel.text = msg;
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *rec = [_records objectAtIndex:indexPath.row];
        [self requestDeleteDocId:[rec objectForKey:@"_docId"]];
        
        [_records removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.userTextField resignFirstResponder];
    [self.msgTextField resignFirstResponder];
    return YES;
}

#pragma mark - Action methods

- (IBAction)refreshAction:(UIBarButtonItem *)sender {
    [self.userTextField resignFirstResponder];
    [self.msgTextField resignFirstResponder];
    self.userTextField.text = nil;
    self.msgTextField.text = nil;
    [self.tableView setEditing:NO animated:YES];
    
    self.records = nil;
    [self.tableView reloadData];
    
    [self requestGetUser:nil];
}

- (IBAction)editAction:(UIBarButtonItem *)sender {
    BOOL editing = !self.tableView.editing;
    [self.tableView setEditing:editing animated:YES];
}

- (IBAction)searchAction:(UIButton *)sender {
    [self.userTextField resignFirstResponder];
    [self.msgTextField resignFirstResponder];
    self.msgTextField.text = nil;
    [self requestGetUser:self.userTextField.text];
}

- (IBAction)postAction:(UIButton *)sender {
    [self.userTextField resignFirstResponder];
    [self.msgTextField resignFirstResponder];
    [self requestPostUser:self.userTextField.text msg:self.msgTextField.text];
    self.userTextField.text = nil;
    self.msgTextField.text = nil;
}

#pragma mark - Private methods

static NSString * const urlData = @"https://hmorijsonenginetest.appspot.com/_je/records";

- (void)requestGetUser:(NSString *)user {
    
    NSMutableString *url = [NSMutableString stringWithString:urlData];
    [url appendString:@"?"];
    if (user && user.length > 0) {
        [url appendString:@"cond="];
        [url appendString:[[NSString stringWithFormat:@"user.eq.%@", user] urlencode]];
    } else {
        [url appendString:@"sort=_createdAt.desc&limit=20"];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    
    NSLog(@"request: %@", request);
    
    __block __weak JEViewController *weakSelf = self;
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[NSOperationQueue mainQueue]
     completionHandler:^(NSURLResponse *response, NSData *data, NSError *errer) {
         NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
         NSLog(@"response: statusCode=%d data=%@", statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
         weakSelf.records = [NSJSONSerialization JSONObjectWithData:data
                                                            options:NSJSONReadingMutableContainers
                                                              error:nil];
         [weakSelf.tableView reloadData];
     }];
}

- (void)requestPostUser:(NSString *)user msg:(NSString *)msg {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlData]];
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"_doc={'user':'%@', 'msg':'%@'}",
                            self.userTextField.text,
                            self.msgTextField.text];
    NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:postData];
    
    NSLog(@"request: %@ postData=%@", request, postString);
    
    __block __weak JEViewController *weakSelf = self;
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[NSOperationQueue mainQueue]
     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
         NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
         NSLog(@"response: statusCode=%d data=%@", statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
         [weakSelf requestGetUser:nil];
     }];
    
}

- (void)requestDeleteDocId:(NSString *)docId {
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@/%@" ,urlData, docId];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"DELETE"];
    
    NSLog(@"request: %@", request);
    
    __block __weak JEViewController *weakSelf = self;
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[NSOperationQueue mainQueue]
     completionHandler:^(NSURLResponse *response, NSData *data, NSError *errer) {
         NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
         NSLog(@"response: statusCode=%d data=%@", statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
         [weakSelf requestGetUser:nil];
     }];
    
}


@end


@implementation NSString (URLEncoding)
- (NSString *)urlencode {
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (__bridge CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8);
}
- (NSString *)urldecode {
    return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                 (__bridge CFStringRef)self,
                                                                                                 CFSTR(""),
                                                                                                 kCFStringEncodingUTF8);
}

@end

