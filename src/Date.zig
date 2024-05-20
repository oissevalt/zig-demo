const std = @import("std");
const time = std.time;
const epoch = time.epoch;

pub const Date = @This();

milliseconds: u10,
seconds: u6,
minutes: u6,
hours: u5,
date: u5,
month: u4,
year: u16,

pub fn nowTimezone(offset: i5) Date {
    const millis = time.milliTimestamp();
    return fromMilliseconds(millis + (@as(i64, offset) * 3_600_000));
}

pub fn nowUtc() Date {
    const millis_timestamp = time.milliTimestamp();
    return fromMilliseconds(millis_timestamp);
}

pub fn fromSeconds(secs: i64) Date {
    return fromMilliseconds(secs * 1000);
}

pub fn fromMilliseconds(millis: i64) Date {
    const secs_timestamp = @divTrunc(millis, 1000);
    const remnant_milis = @mod(millis, 1000);

    const epoch_secs = epoch.EpochSeconds{ .secs = @intCast(secs_timestamp) };
    const day_secs = epoch_secs.getDaySeconds();

    const epoch_day = epoch_secs.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();

    const hours = day_secs.getHoursIntoDay();
    const minutes = day_secs.getMinutesIntoHour();
    const seconds = day_secs.getSecondsIntoMinute();

    return .{
        .milliseconds = @intCast(remnant_milis),
        .seconds = seconds,
        .minutes = minutes,
        .hours = hours,
        .date = month_day.day_index + 1,
        .month = month_day.month.numeric(),
        .year = year_day.year,
    };
}

test "Date" {
    const date = nowTimezone(8);
    std.debug.print(
        "{d}-{d:0>2}:{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}.{d:0>3}\n",
        .{ date.year, date.month, date.date, date.hours, date.minutes, date.seconds, date.milliseconds },
    );
}
