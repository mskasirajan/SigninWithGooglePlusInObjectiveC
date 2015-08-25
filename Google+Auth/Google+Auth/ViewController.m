//
//  ViewController.m
//  Google+Auth
//
//  Created by kasirajan on 19/08/15.
//  Copyright © 2015 kasi. All rights reserved.
//

#import "ViewController.h"

NSString *callbakc =  @"http://localhost";
NSString *client_id = @"YOUR CLIENT ID";
NSString *scope = @"https://www.googleapis.com/auth/userinfo.email+https://www.googleapis.com/auth/userinfo.profile+https://www.google.com/reader/api/0/subscription";
NSString *secret = @"YOUR SECRECT ID";
NSString *visibleactions = @"http://schemas.google.com/AddActivity";

@interface ViewController () {
    NSString *authAccessToken;
    UIAlertController *alertController;
}

@property (strong, nonatomic) NSMutableData *receivedData;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self showAlertViewWithTitle:@"" message:@"Please wait..." okAction:NO];
    
    NSString *url = [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=%@&redirect_uri=%@&scope=%@&data-requestvisibleactions=%@",client_id,callbakc,scope,visibleactions];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
    
    [_webView loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - WebView Delegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    
    [self performSelector:@selector(progressDelay:) withObject:nil afterDelay:0.0];
    if ([[[request URL] host] isEqualToString:@"localhost"]) {
        
        // Extract oauth_verifier from URL query
        NSString* verifier = nil;
        NSArray* urlParams = [[[request URL] query] componentsSeparatedByString:@"&"];
        for (NSString* param in urlParams) {
            if (![param isEqualToString:@"error=access_denied"]) {
                NSArray* keyValue = [param componentsSeparatedByString:@"="];
                NSString* key = [keyValue objectAtIndex:0];
                if ([key isEqualToString:@"code"]) {
                    verifier = [keyValue objectAtIndex:1];
                    break;
                }
            }
            else {
                [self.navigationController popViewControllerAnimated:NO];
            }
        }
        
        if (!verifier==0) {
            [self showAlertViewWithTitle:@"" message:@"Please wait" okAction:NO];
            
            NSString *data = [NSString stringWithFormat:@"code=%@&client_id=%@&redirect_uri=%@&grant_type=authorization_code", verifier,client_id,callbakc];
            NSString *url = [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/token"];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
            
            [request setHTTPShouldHandleCookies:NO];
            
            NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            NSLog(@"Connection: %@", theConnection);
            
            self.receivedData = [[NSMutableData alloc] init];
        }
        else {
            // cancel button click
            NSLog(@"not Verified!!");
        }
        
        return NO;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    // show progress
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [alertController dismissViewControllerAnimated:YES completion:nil];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    if (error.code==102) //Frame load interrupted
        return;
    
    [alertController dismissViewControllerAnimated:YES completion:nil];
    [self showAlertViewWithTitle:@"Error" message:[error localizedDescription] okAction:YES];
}

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self showAlertViewWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", error] okAction:YES];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    NSString *response = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
    
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *tokenData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    if ([tokenData objectForKey:@"access_token"]) {
        authAccessToken = [tokenData objectForKey:@"access_token"];
        [self getUserInfo:authAccessToken];
    }
    else {
        [alertController dismissViewControllerAnimated:YES completion:nil];
        NSLog(@"RESULT: %@", tokenData);
        [self showAlertViewWithTitle:[tokenData objectForKey:@"name"] message:[NSString stringWithFormat:@"%@", tokenData] okAction:YES];
        
        // Flush all cached data
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }
    
}

#pragma mark - Private Method Implementation

-(void)getUserInfo:(NSString *)token {
    NSString *url = [NSString stringWithFormat:@"https://www.googleapis.com/oauth2/v1/userinfo?access_token=%@",token];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    [request setHTTPShouldHandleCookies:NO];
    
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
    NSLog(@"Connection: %@", theConnection);
    
    self.receivedData = [[NSMutableData alloc] init];
    
}

-(void)progressDelay:(id)sender {
    // Dismiss progress
}

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message okAction:(BOOL)action {
    // init alert controller
    alertController = [UIAlertController alertControllerWithTitle:title
                                                          message:message
                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    // set ok action
    if (action) {
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {
                                       
                                       [alertController dismissViewControllerAnimated:YES completion:nil];
                                   }];
        
        [alertController addAction:okAction];
    }
    
    // show alert controller
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

@end
