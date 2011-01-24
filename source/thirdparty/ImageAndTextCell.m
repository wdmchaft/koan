//
// ImageAndTextCell.m
// Abstract: Subclass of NSTextFieldCell which can display text and an image simultaneously.
// Version: 1.0
//
// Copyright (C) 2009 Apple Inc. All Rights Reserved.
//
// License:
//
//   Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//   Inc. ("Apple") in consideration of your agreement to the following
//   terms, and your use, installation, modification or redistribution of
//   this Apple software constitutes acceptance of these terms.  If you do
//   not agree with these terms, please do not use, install, modify or
//   redistribute this Apple software.
//
//   In consideration of your agreement to abide by the following terms, and
//   subject to these terms, Apple grants you a personal, non-exclusive
//   license, under Apple's copyrights in this original Apple software (the
//   "Apple Software"), to use, reproduce, modify and redistribute the Apple
//   Software, with or without modifications, in source and/or binary forms;
//   provided that if you redistribute the Apple Software in its entirety and
//   without modifications, you must retain this notice and the following
//   text and disclaimers in all such redistributions of the Apple Software.
//   Neither the name, trademarks, service marks or logos of Apple Inc. may
//   be used to endorse or promote products derived from the Apple Software
//   without specific prior written permission from Apple.  Except as
//   expressly stated in this notice, no other rights or licenses, express or
//   implied, are granted by Apple herein, including but not limited to any
//   patent rights that may be infringed by your derivative works or by other
//   works in which the Apple Software may be incorporated.
//
//   The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//   MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//   THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//   FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//   OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//   IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//   OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//   INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//   MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//   AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//   STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//   POSSIBILITY OF SUCH DAMAGE.
//
// Modifications by Tyler Berry.
// Copyright (c) 2011 3James Software.
//

#import "ImageAndTextCell.h"

@implementation ImageAndTextCell

@synthesize image;

- (id) init
{
  if (!(self = [super init]))
    return nil;
	
  [self setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
  [self setLineBreakMode: NSLineBreakByTruncatingTail];
  [self setSelectable: YES];
  
  return self;
}

- (void) dealloc
{
  [image release];
  [super dealloc];
}

- (id) copyWithZone: (NSZone *) zone
{
  ImageAndTextCell *cell = (ImageAndTextCell *) [super copyWithZone: zone];
  cell->image = [image retain];
  return cell;
}

- (NSRect) imageRectForBounds: (NSRect) cellFrame
{
  NSRect result;
  
  if (image != nil)
  {
    result.size = [self.image size];
    result.origin = cellFrame.origin;
    result.origin.x += 3;
    result.origin.y += ceil ((cellFrame.size.height - result.size.height) / 2);
  }
  else
    result = NSZeroRect;
  
  return result;
}

- (NSRect) titleRectForBounds: (NSRect) cellFrame
{
	NSRect result;
  
  if (image != nil)
  {
    CGFloat imageWidth = [self.image size].width;
    result = cellFrame;
    result.origin.x += (3 + imageWidth);
    result.size.width -= (3 + imageWidth);
  }
  else
    result = [super titleRectForBounds: cellFrame];
  
  return result;
}

- (void) editWithFrame: (NSRect) cellFrame inView: (NSView *) controlView editor: (NSText *) editor delegate: (id) delegate event: (NSEvent *) event
{
  NSRect textFrame, imageFrame;
  NSDivideRect (cellFrame, &imageFrame, &textFrame, 3 + [self.image size].width, NSMinXEdge);
  
	[super editWithFrame: textFrame
                inView: controlView
                editor: editor
              delegate: delegate
                 event: event];
}

- (void) selectWithFrame: (NSRect) cellFrame inView: (NSView *) controlView editor: (NSText *) editor delegate: (id) delegate start: (NSInteger) selectStart length: (NSInteger) selectLength
{
  NSRect textFrame, imageFrame;
  NSDivideRect (cellFrame, &imageFrame, &textFrame, 3 + [self.image size].width, NSMinXEdge);
  
	[super selectWithFrame: textFrame
                  inView: controlView
                  editor: editor
                delegate: delegate
                   start: selectStart
                  length: selectLength];
}

- (void) drawWithFrame: (NSRect) cellFrame inView: (NSView *) controlView
{
  if (image != nil)
  {
    NSRect imageFrame;
    NSSize imageSize = [self.image size];
    
    NSDivideRect (cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, NSMinXEdge);
    
    if ([self drawsBackground])
    {
      [[self backgroundColor] set];
      NSRectFill (imageFrame);
    }
    
    imageFrame.origin.x += 3;
    imageFrame.size = imageSize;
    
    if ([controlView isFlipped])
      imageFrame.origin.y += ceil ((cellFrame.size.height + imageFrame.size.height) / 2);
    else
      imageFrame.origin.y += ceil ((cellFrame.size.height - imageFrame.size.height) / 2);
    
    [self.image compositeToPoint: imageFrame.origin operation: NSCompositeSourceOver];
  }
  
  [super drawWithFrame: cellFrame inView: controlView];
}

- (NSSize) cellSize
{
  NSSize cellSize = [super cellSize];
  cellSize.width += (self.image ? [self.image size].width : 0) + 3;
  return cellSize;
}

- (NSUInteger) hitTestForEvent: (NSEvent *) event inRect: (NSRect) cellFrame ofView: (NSView *) controlView
{
	NSPoint point = [controlView convertPoint: [event locationInWindow] fromView: nil];
  
  // If we have an image, we need to see if the user clicked on the image portion.
  if (image != nil)
  {
    NSSize imageSize = [self.image size];
    NSRect imageFrame;
    NSDivideRect (cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, NSMinXEdge);
    
    imageFrame.origin.x += 3;
    imageFrame.size = imageSize;
    
    // If the point is in the image rect, then it is a content hit.
    if (NSMouseInRect (point, imageFrame, [controlView isFlipped]))
    {
      // We consider this just a content area. It is not trackable, nor it it editable text. If it was, we would or in the additional items.
      // By returning the correct parts, we allow NSTableView to correctly begin an edit when the text portion is clicked on.
      return NSCellHitContentArea;
    }        
  }
  
  // At this point, the cellFrame has been modified to exclude the portion for the image.
  // Let the superclass handle the hit testing at this point.
  return [super hitTestForEvent: event inRect: cellFrame ofView: controlView];    
}

@end
