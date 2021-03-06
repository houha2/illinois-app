//
//  NSDictionary+UIUCExplore.h
//  UIUCUtils
//
//  Created by Mihail Varbanov on 5/9/19.
//  Copyright 2020 Board of Trustees of the University of Illinois.
    
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//    http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "NSDictionary+UIUCExplore.h"

#import "NSDictionary+InaTypedValue.h"
#import "NSDate+InaUtils.h"
#import "NSDate+UIUCUtils.h"

@implementation NSDictionary(UIUCExplore)

- (UIUCExploreType)uiucExploreType {
	if ([self objectForKey:@"eventId"] != nil) {
		return UIUCExploreType_Event;
	}
	else if ([self objectForKey:@"DiningOptionID"] != nil) {
		return UIUCExploreType_Dining;
	}
	else if ([self objectForKey:@"campus_name"] != nil) {
		return UIUCExploreType_Laundry;
	}
	else if ([self objectForKey:@"lot_id"] != nil) {
		return UIUCExploreType_Parking;
	}
	else if ([self objectForKey:@"explores"] != nil) {
		return UIUCExploreType_Explores;
	}
	else {
		return UIUCExploreType_Unknown;
	}
}

- (UIUCExploreType)uiucExploreContentType {
	return [self inaIntegerForKey:@"exploresContentType" defaults:UIUCExploreType_Unknown];
}

- (NSString*)uiucExploreMarkerHexColor {
	UIUCExploreType exploreType = self.uiucExploreType;
	return (exploreType == UIUCExploreType_Explores) ?
		[self inaStringForKey:@"color" defaults:@"#13294b"] :
		[self.class uiucExploreMarkerHexColorFromType:exploreType];
}

+ (NSString*)uiucExploreMarkerHexColorFromType:(UIUCExploreType)type {
	switch (type) {
		case UIUCExploreType_Event:  return @"#e84a27"; // illinoisOrange
		case UIUCExploreType_Dining: return @"#f29835"; // mangо
		default:                     return @"#5fa7a3"; // teal
	}
}

- (NSString*)uiucExploreTitle {
	switch (self.uiucExploreType) {
		case UIUCExploreType_Parking: return [self inaStringForKey:@"lot_name"];
		default:                      return [self inaStringForKey:@"title"];
	}
}

- (NSString*)uiucExploreDescription {
	UIUCExploreType exploreType = self.uiucExploreType;
	if (exploreType == UIUCExploreType_Event) {
		NSString *eventTime = [self inaStringForKey:@"startDateLocal"];
		if (0 < eventTime.length) {
			NSDate *eventDate = [NSDate inaDateFromString:eventTime format:@"yyyy-MM-dd'T'HH:mm:ss"];
			return [eventDate formatUUICTime] ?: eventTime;
		}
	}
	else if (exploreType == UIUCExploreType_Laundry) {
		NSString *status = [self inaStringForKey:@"status"];
		if (0 < status.length) {
			return status;
		}
	}
	
	return [self.uiucExploreLocation inaStringForKey:@"description"];
}

- (NSArray*)uiucExplores {
	return [self inaArrayForKey:@"explores"];
}

- (NSDictionary*)uiucExploreLocation {
	switch (self.uiucExploreType) {
		case UIUCExploreType_Parking:  return [self inaDictForKey:@"entrance"];
		default:                       return [self inaDictForKey:@"location"];
	}
}

- (NSString*)uiucExploreAddress {
	switch (self.uiucExploreType) {
		case UIUCExploreType_Parking:  return [self inaStringForKey:@"lot_address1"];
		case UIUCExploreType_Explores: return [self inaStringForKey:@"address"];
		default:                       return nil;
	}
}

- (NSArray*)uiucExplorePolygon {
	return [self inaArrayForKey:@"polygon"];

}

- (CLLocationCoordinate2D)uiucExploreLocationCoordinate {
	NSDictionary *location = self.uiucExploreLocation;
	return (location != nil) ? CLLocationCoordinate2DMake([location inaDoubleForKey:@"latitude"], [location inaDoubleForKey:@"longitude"]) : kCLLocationCoordinate2DInvalid;
}

- (int)uiucExploreLocationFloor {
	NSDictionary *location = self.uiucExploreLocation;
	return [location inaIntForKey:@"floor"];
}

+ (NSDictionary*)uiucExploreFromGroup:(NSArray*)explores {
	if (explores != nil) {
		
		UIUCExploreType exploresType = UIUCExploreType_Unknown;
		for (NSDictionary *explore in explores) {
			UIUCExploreType exploreType = explore.uiucExploreType;
			if (exploresType == UIUCExploreType_Unknown) {
				exploresType = exploreType;
			}
			else if (exploresType != exploreType) {
				exploresType = UIUCExploreType_Unknown;
				break;
			}
		}
		
		NSString *exploresName = nil;
		switch (exploresType) {
			case UIUCExploreType_Event:   exploresName = @"Events"; break;
			case UIUCExploreType_Dining:  exploresName = @"Dinings"; break;
			case UIUCExploreType_Laundry: exploresName = @"Laundries"; break;
			case UIUCExploreType_Parking: exploresName = @"Parkings"; break;
			default:                      exploresName = @"Explores"; break;
		}
		
		NSString *exploresColor = (exploresType != UIUCExploreType_Unknown) ? [self.class uiucExploreMarkerHexColorFromType:exploresType] : @"#13294b";

		return @{
			@"type" : @"explores",
			@"title" : [NSString stringWithFormat:@"%d %@", (int)explores.count, exploresName],
			@"location" : [explores.firstObject inaDictForKey:@"location"] ?: [NSNull null],
			@"address": [explores.firstObject inaStringForKey:@"lot_address1"] ?: [NSNull null],
			@"color": exploresColor,
			@"exploresContentType": @(exploresType),
			@"explores" : explores,
		};
	}
	return nil;
}


@end

// UIUCExploreType

NSString* UIUCExploreTypeToString(UIUCExploreType exploreType) {
	switch (exploreType) {
		case UIUCExploreType_Event:    return @"event";
		case UIUCExploreType_Dining:   return @"dining";
		case UIUCExploreType_Laundry:  return @"laundry";
		case UIUCExploreType_Parking:  return @"parking";
		case UIUCExploreType_Explores: return @"explores";
		default: return nil;
	}
}

UIUCExploreType UIUCExploreTypeFromString(NSString* value) {
	if (value != nil) {
		if ([value isEqualToString:@"event"]) {
			return UIUCExploreType_Event;
		}
		else if ([value isEqualToString:@"dining"]) {
			return UIUCExploreType_Dining;
		}
		else if ([value isEqualToString:@"laundry"]) {
			return UIUCExploreType_Laundry;
		}
		else if ([value isEqualToString:@"parking"]) {
			return UIUCExploreType_Parking;
		}
		else if ([value isEqualToString:@"explores"]) {
			return UIUCExploreType_Explores;
		}
	}
	return UIUCExploreType_Unknown;
}
