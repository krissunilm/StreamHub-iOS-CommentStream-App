//
//  LFSHeader.h
//  CommentStream
//
//  Created by Eugene Scherba on 9/30/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <Foundation/Foundation.h>

// This is a convenience class to group resource-related information together
// The resource is usually some kind of URL but it could also
// be, e.g. author profile with a twitter handle as identifier instead
// of URL.
@interface LFSResource : NSObject

@property (strong, nonatomic) UIImage *icon;
@property (copy, nonatomic) NSString *iconURLString;
@property (copy, nonatomic) NSString *attributeString;
@property (copy, nonatomic) NSString *displayString;
@property (copy, nonatomic) NSString *identifier;

-(id)initWithIdentifier:(NSString*)detailString
        attributeString:(NSString*)attributeString
          displayString:(NSString*)mainString
                   icon:(UIImage*)iconImage;

-(id)initWithIdentifier:(NSString*)urlString
          displayString:(NSString*)displayString
                   icon:(UIImage*)iconImage;
@end
