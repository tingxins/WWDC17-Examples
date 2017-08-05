//
//  ViewController.m
//  TXLocationTechDemo
//
//  Created by tingxins on 13/07/2017.
//  Copyright © 2017 tingxins. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <Contacts/Contacts.h>
#import <CoreMotion/CoreMotion.h>

@interface ViewController ()<CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *manager;

@property (strong, nonatomic) CLGeocoder *geocoder;

@property (weak, nonatomic) IBOutlet UILabel *locateResultLabel;

@end

@implementation ViewController

- (CLGeocoder *)geocoder {
    if (_geocoder) return _geocoder;
    _geocoder = [[CLGeocoder alloc] init];
    return _geocoder;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 创建 Location Mannager
    [self setupLocationManager];
    
    // 程序进入后台通知
    [self addNotifications];
    
    // PostalAddress 解析测试
    [self postalAddressTest];
}

- (void)setupLocationManager {
    CLLocationManager *manager = [[CLLocationManager alloc] init];
    self.manager = manager;
    manager.allowsBackgroundLocationUpdates = YES;
    manager.delegate = self;
}

- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startingBackgroundLocation) name:@"TXBackgroundStartUpdatingLocation" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stoppingBackgroundLocation) name:@"TXBackgroundStopUpdatingLocation" object:nil];
}

#pragma mark - Customs

/** Notes: App has not access privacy-sensitive data without a usage description. The app's Info.plist must contain an NSLocationXXXXXDescription key with a string value explaining to the user how the app uses this data */
- (void)requestAuthorization {
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            [self.manager requestWhenInUseAuthorization];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            [self.manager requestLocation];
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self.manager requestAlwaysAuthorization];
            break;
        case kCLAuthorizationStatusRestricted:
            NSLog(@"Restricted");
            break;
        case kCLAuthorizationStatusDenied:
            NSLog(@"Denied");
            break;
            
        default:
            break;
    }
}

- (void)serialLocation:(CLLocation *)location {
    if (!location) return;
    NSLog(@"%s--%lf---%lf", __func__, location.coordinate.longitude,location.coordinate.latitude);
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (!error && placemarks.count) {
            NSLog(@"**********reverseGeocodeLocation************");
            CLPlacemark *placeMark = placemarks.lastObject;
            NSLog(@"%@", placeMark.addressDictionary);
            if (@available(iOS 11.0, *)) {
                NSLog(@"%@--%@", placeMark.name, placeMark.postalAddress);
            } else {
                // Fallback on earlier versions
                NSLog(@"%@", placeMark.name);
            }
            self.locateResultLabel.text = [NSString stringWithFormat:@"Current Location:%@", placeMark.name];
            NSLog(@"**********reverseGeocodeLocation************");
        }
    }];
}

- (void)postalAddressTest {
    CNMutablePostalAddress *homeAddress = [[CNMutablePostalAddress alloc] init];
    homeAddress.street = @"Keyan Road No.9 Nanshan";
    homeAddress.city = @"Shenzhen";
    homeAddress.state = @"Guangdong";
    homeAddress.postalCode = @"518000";
    homeAddress.country = @"China";
    homeAddress.ISOCountryCode = @"CN";
    
    if (@available(iOS 11.0, *)) {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_Hans_CN"];
        [self.geocoder geocodePostalAddress:homeAddress preferredLocale:locale completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            if (!error && placemarks.count) {
                NSLog(@"**********geocodePostalAddress-preferredLocale************");
                CLPlacemark *placemark = placemarks.lastObject;
                NSLog(@"%@--%@", placemark.name, placemark.postalAddress);
                NSLog(@"**********geocodePostalAddress-preferredLocale************");
            }
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (IBAction)locating:(UIButton *)sender {
    NSLog(@"%s", __func__);
    [self.manager requestLocation];
}

#pragma mark - Background Notifications

- (void)startingBackgroundLocation {
    NSLog(@"%s", __func__);
    // 1.单次更新
//    [self.manager requestLocation];
    // 2.持续更新
    [self.manager startUpdatingLocation];
}

- (void)stoppingBackgroundLocation {
    NSLog(@"%s", __func__);
    [self.manager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"RequestAuthorization:%d", status);
    [self requestAuthorization];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSLog(@"%s", __func__);
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways) {
        [self serialLocation:locations.lastObject];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError:%@",error);
}

@end
