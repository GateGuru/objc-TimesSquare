//
//  TSQCalendarRowCell.m
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "TSQCalendarRowCell.h"
#import "TSQCalendarView.h"


@interface TSQCalendarRowCell ()
{
    NSUInteger buttonStates[7];
}

@property (nonatomic, assign) NSInteger indexOfTodayButton;
@property (nonatomic, assign) NSInteger indexOfSelectedButton;

@property (nonatomic, strong) NSDateFormatter *dayFormatter;
@property (nonatomic, strong) NSDateFormatter *accessibilityFormatter;

@property (nonatomic, strong) NSDateComponents *todayDateComponents;
@property (nonatomic) NSInteger monthOfBeginningDate;

@property (nonatomic, strong, readwrite) NSArray *dayButtons;
@property (nonatomic, strong, readwrite) NSArray *notThisMonthButtons;

@end

static const NSInteger maxValueForRange = 14;

@implementation TSQCalendarRowCell

- (id)initWithCalendar:(NSCalendar *)calendar reuseIdentifier:(NSString *)reuseIdentifier;
{
    self = [super initWithCalendar:calendar reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    return self;
}

- (void)configureButton:(UIButton *)button;
{
    button.titleLabel.font = self.textFont;
    button.titleLabel.shadowOffset = self.shadowOffset;
    button.adjustsImageWhenDisabled = NO;
    [button setTitleColor:self.textColor forState:UIControlStateNormal];
    [button setTitleColor:self.textColorDisabled forState:UIControlStateDisabled];
    [button setTitleShadowColor:self.textColorShadow forState:UIControlStateNormal];
    [button setBackgroundImage:nil forState:UIControlStateNormal];
}

- (void)configureSelectedButton:(UIButton *)button;
{
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    
    if (self.calendarView.selectionMode == TSQCalendarSelectionModeDateRange) {
        if ((self.calendarView.selectedStartDate) && (!self.calendarView.selectedEndDate)) {
            [button setBackgroundImage:[self selectedBackgroundImage] forState:UIControlStateNormal];
        } else if ((self.calendarView.selectedStartDate) && (self.calendarView.selectedEndDate)){
            [button setBackgroundImage:[self selectedMiddleDaysOfRangeBackgroundImage] forState:UIControlStateNormal];
            [button setTitleColor:self.textColorMiddleRangeDays forState:UIControlStateNormal];
            [button setTitleColor:self.textColorMiddleRangeDays forState:UIControlStateDisabled];
        }
    }
    
    [button setTitleShadowColor:[UIColor colorWithWhite:0.0f alpha:0.75f] forState:UIControlStateNormal];
    button.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f / [UIScreen mainScreen].scale);
}

- (void)configureTodayButton:(UIButton *)button;
{
    [button setTitleColor:self.todayTextColor forState:UIControlStateNormal];
    [button setBackgroundImage:[self todayBackgroundImage] forState:UIControlStateNormal];
    [button setTitleShadowColor:self.todayShadowColor forState:UIControlStateNormal];
    button.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f / [UIScreen mainScreen].scale);
}

- (void)configureFirstButton:(UIButton *)button
{
    [button setTitleColor: self.textColorFirstAndlastRangeDay forState:UIControlStateNormal];
    [button setTitleColor: self.textColorFirstAndlastRangeDay forState:UIControlStateDisabled];
    [button setBackgroundImage:[self selectedFirstDayOfRangeBackgroundImage] forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor colorWithWhite:0.0f alpha:0.75f] forState:UIControlStateNormal];
    button.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f / [UIScreen mainScreen].scale);
}

- (void)configureLastButton:(UIButton *)button
{
    [button setTitleColor: self.textColorFirstAndlastRangeDay forState:UIControlStateNormal];
    [button setTitleColor: self.textColorFirstAndlastRangeDay forState:UIControlStateDisabled];
    [button setBackgroundImage:[self selectedLastDayOfRangeBackgroundImage] forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor colorWithWhite:0.0f alpha:0.75f] forState:UIControlStateNormal];
    button.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f / [UIScreen mainScreen].scale);
}

- (void)createDayButtons;
{
    NSMutableArray *dayButtons = [NSMutableArray arrayWithCapacity:self.daysInWeek];
    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        UIButton *button = [[UIButton alloc] initWithFrame:self.contentView.bounds];
        [button addTarget:self action:@selector(dateButtonPressed:) forControlEvents:UIControlEventTouchDown];
        [dayButtons addObject:button];
        [self.contentView addSubview:button];
        [self configureButton:button];        
    }
    self.dayButtons = dayButtons;
}

- (void)createNotThisMonthButtons;
{
    NSMutableArray *notThisMonthButtons = [NSMutableArray arrayWithCapacity:self.daysInWeek];
    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        UIButton *button = [[UIButton alloc] initWithFrame:self.contentView.bounds];
        [notThisMonthButtons addObject:button];
        [self.contentView addSubview:button];
        [self configureButton:button];

        button.enabled = NO;
        UIColor *backgroundPattern = [UIColor colorWithPatternImage:[self notThisMonthBackgroundImage]];
        button.backgroundColor = backgroundPattern;
    }
    self.notThisMonthButtons = notThisMonthButtons;
}

- (void)setBeginningDate:(NSDate *)date;
{
    _beginningDate = date;
    
    if (!self.dayButtons) {
        [self createDayButtons];
        [self createNotThisMonthButtons];
    }

    NSDateComponents *offset = [NSDateComponents new];
    offset.day = 1;

    self.indexOfTodayButton = -1;
    
    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        NSString *title = [self.dayFormatter stringFromDate:date];
        NSString *accessibilityLabel = [self.accessibilityFormatter stringFromDate:date];
        [self.dayButtons[index] setTitle:title forState:UIControlStateNormal];
        [self.dayButtons[index] setAccessibilityLabel:accessibilityLabel];
        [self.notThisMonthButtons[index] setTitle:title forState:UIControlStateNormal];
        [self.notThisMonthButtons[index] setTitle:title forState:UIControlStateDisabled];
        [self.notThisMonthButtons[index] setAccessibilityLabel:accessibilityLabel];
        
        NSDateComponents *thisDateComponents = [self.calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:date];

        [self.notThisMonthButtons[index] setHidden:YES];
        [self.dayButtons[index] setHidden:NO];
        
        NSInteger thisDayMonth = thisDateComponents.month;
        if (self.monthOfBeginningDate != thisDayMonth) {
            [self.dayButtons[index] setHidden:YES];
            if (self.showsNotThisMonth) {
                [self.notThisMonthButtons[index] setHidden:NO];
            }
        } else {
            if ([self.todayDateComponents isEqual:thisDateComponents]) {
                self.indexOfTodayButton = index;
            }
            UIButton *button = self.dayButtons[index];
            button.enabled = ![self.calendarView.delegate respondsToSelector:@selector(calendarView:shouldSelectDate:)] || [self.calendarView.delegate calendarView:self.calendarView shouldSelectDate:date];
            
            if (self.disablesDatesEarlierThanToday && (self.todayDateComponents.year == thisDateComponents.year && self.todayDateComponents.month == thisDateComponents.month && thisDateComponents.day < self.todayDateComponents.day)) {
                button.enabled = NO;
            }
        }

        date = [self.calendar dateByAddingComponents:offset toDate:date options:0];
        buttonStates[index] = 0;
    }
}

- (void)setBottomRow:(BOOL)bottomRow;
{
    UIImageView *backgroundImageView = (UIImageView *)self.backgroundView;
    if ([backgroundImageView isKindOfClass:[UIImageView class]] && _bottomRow == bottomRow) {
        return;
    }

    _bottomRow = bottomRow;
    
    self.backgroundView = [[UIImageView alloc] initWithImage:self.backgroundImage];
    
    [self setNeedsLayout];
}

- (void)selectDate:(NSDate *)selectedDate
{
    self.calendarView.selectionError = nil;
    
    if (self.calendarView.isScrolling) {
        return;
    }

    if (self.calendarView.selectionMode == TSQCalendarSelectionModeDay) {
        self.calendarView.selectedDate = ([self.calendarView.selectedDate isEqual:selectedDate]) ? nil : selectedDate;
    } else {
        if (self.calendarView.selectedEndDate) {
            self.calendarView.selectedEndDate = nil;
            self.calendarView.selectedStartDate = selectedDate;
        } else if (self.calendarView.selectedStartDate && ([selectedDate compare:self.calendarView.selectedStartDate] == NSOrderedDescending)) {
            if ([self differenceInDaysBetweenStartDate:self.calendarView.selectedStartDate andEndDate:selectedDate] <= maxValueForRange) {
                self.calendarView.selectedEndDate = selectedDate;
            }
        } else if ([self.calendarView.selectedStartDate isEqual:selectedDate]) {
            self.calendarView.selectedStartDate = nil;
        } else {
            if ([self differenceInDaysBetweenStartDate:[NSDate date] andEndDate:selectedDate] >= 0) {
                self.calendarView.selectedStartDate = selectedDate;
            }
        }
    }
    
    if (self.calendarView.selectedStartDate && selectedDate && [self differenceInDaysBetweenStartDate:self.calendarView.selectedStartDate andEndDate:selectedDate] > maxValueForRange) {
        self.calendarView.selectionError = TSQCalendarErrorSelectionMaxRange;
    }
}

- (IBAction)dateButtonPressed:(id)sender;
{
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = [self.dayButtons indexOfObject:sender];
    NSDate *selectedDate = [self.calendar dateByAddingComponents:offset toDate:self.beginningDate options:0];
    
    [self selectDate:selectedDate];
}

- (NSInteger)differenceInDaysBetweenStartDate:(NSDate *)startDate andEndDate:(NSDate *)endDate
{
    NSUInteger unitFlags = NSDayCalendarUnit;
    NSDateComponents *components = [self.calendar components:unitFlags fromDate:startDate toDate:endDate options: 0];
    return [components day];
}

- (void)layoutSubviews;
{
    if (!self.backgroundView) {
        [self setBottomRow:NO];
    }
    
    [super layoutSubviews];
    
    self.backgroundView.frame = self.bounds;
}

- (void)layoutViewsForColumnAtIndex:(NSUInteger)index inRect:(CGRect)rect;
{
    UIButton *dayButton = self.dayButtons[index];
    UIButton *notThisMonthButton = self.notThisMonthButtons[index];
    
    dayButton.frame = rect;
    notThisMonthButton.frame = rect;
    
    if (buttonStates[index] == 1) {
        [self configureSelectedButton:dayButton];
    }  else  if (buttonStates[index] == 2) {
        [self configureFirstButton:dayButton];
    } else  if (buttonStates[index] == 3) {
        [self configureLastButton:dayButton];
    } else if (self.indexOfTodayButton == (NSInteger)index) {
        [self configureTodayButton:dayButton];
    } else {
        [self configureButton:dayButton];
        if (!dayButton.enabled) {
            [dayButton setTitleColor:[self.textColor colorWithAlphaComponent:0.5f] forState:UIControlStateNormal];
        }
        
    }
}

- (void)deselectColumnForDate:(NSDate *)date;
{
    if (!date) return;
    
    NSInteger indexOfButtonForDate = [self indexOfColumnForDate:date];
    if (indexOfButtonForDate >= 0) {
        buttonStates[indexOfButtonForDate] = 0;
    }
    
    [self setNeedsLayout];
}

- (void)selectColumnForDate:(NSDate *)date;
{
    if (!date) return;
    
    NSInteger indexOfButtonForDate = [self indexOfColumnForDate:date];
    if (indexOfButtonForDate >= 0) {
        buttonStates[indexOfButtonForDate] = 1;
        if (self.calendarView.selectedStartDate && self.calendarView.selectedEndDate) {
            if ([self.calendarView.selectedStartDate isEqual:date]) {
                buttonStates[indexOfButtonForDate] = 2;
            } else if ([self.calendarView.selectedEndDate isEqual:date]) {
                buttonStates[indexOfButtonForDate] = 3;
            }
        }
    }
    
    [self setNeedsLayout];
}


- (NSDateFormatter *)dayFormatter;
{
    if (!_dayFormatter) {
        _dayFormatter = [NSDateFormatter new];
        _dayFormatter.calendar = self.calendar;
        _dayFormatter.dateFormat = @"d";
    }
    return _dayFormatter;
}

- (NSDateFormatter *)accessibilityFormatter;
{
    if (!_accessibilityFormatter) {
        _accessibilityFormatter = [NSDateFormatter new];
        _accessibilityFormatter.calendar = self.calendar;
        _accessibilityFormatter.dateStyle = NSDateFormatterLongStyle;
    }
    return _accessibilityFormatter;
}

- (NSInteger)monthOfBeginningDate;
{
    if (!_monthOfBeginningDate) {
        _monthOfBeginningDate = [self.calendar components:NSMonthCalendarUnit fromDate:self.firstOfMonth].month;
    }
    return _monthOfBeginningDate;
}

- (void)setFirstOfMonth:(NSDate *)firstOfMonth;
{
    [super setFirstOfMonth:firstOfMonth];
    self.monthOfBeginningDate = 0;
}

- (NSDateComponents *)todayDateComponents;
{
    if (!_todayDateComponents) {
        self.todayDateComponents = [self.calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:[NSDate date]];
    }
    return _todayDateComponents;
}


#pragma mark - Columns

- (NSInteger *)indexOfColumnForDate:(NSDate *)date;
{
    NSInteger indexOfButtonForDate = -1;
    if (date) {
        NSInteger thisDayMonth = [self.calendar components:NSMonthCalendarUnit fromDate:date].month;
        if (self.monthOfBeginningDate == thisDayMonth) {
            indexOfButtonForDate = [self.calendar components:NSDayCalendarUnit fromDate:self.beginningDate toDate:date options:0].day;
            if (indexOfButtonForDate >= (NSInteger)self.daysInWeek) {
                indexOfButtonForDate = -1;
            }
        }
    }
    return indexOfButtonForDate;
}

@end
