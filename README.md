Timelanes displays visual Widgets horizontally scaled by a date within a date range, 
and positioned vertically in timelanes (like swimlanes)

## Features

* Show how different events relate to each other relative to time
* Build visual timelines

![](readme-example-1.jpg?raw=true)

To any time scale

![](readme-example-2.jpg?raw=true)




## Usage

In a builder, create a Timelanes with the names of the timelanes above and below the timeline, 
the date range of the timeline itself, a fallback builder function (see below), and a set of TimeEvent instances. 
Each of these instances has a date or date range, a timelane index, a title, a priority 
(for handling overlapping widgets), a horizontal offset, and a builder function which returns a widget

The builder function (either specific to a TimeEvent or the TimeLanes fallback) receives the event instance, 
the height of the lane, the scale of pixels per minute, and an indication if the event's date range is 
completely within the timeline date range or if it extends before or after

Without any defined builder functions, every TimeEvent displays its title

When built, Timelanes gathers the widget from every TimeEvent that is within the timeline's date range. This allows
the same set of events to work if the timeline's date-range changes (e.g. zooming in). It calculates the pixels-per-minute
and places each of these widgets in its timelane horizontally according to its TimeEvent date or date range. The 
priority value determines which widgets is on top if they overlap. These widgets can have tooltips, mouse reactions,
URL launchers, etc.
```dart
 return Expanded(child: Timelanes(
    earliestDate: DateTime(1330),
    latestDate: DateTime(1850),
    lanesAbove: ["lane 1", "lane 2"],
    lanesBelow: ["lane 3", "lane 4"],
    events: [
      TimeEvent(start: DateTime(300), end: DateTime(1230), title: "not shown: out of bounds", laneIndex: 0),
      TimeEvent(
          start: DateTime(1500),
          title: "show a box",
          laneIndex: 3,
          builder: (TimeEvent event, double maximumHeight, double pixelsPerMinute, EventAlignment eventAlignment) {
            return Container(
              height: maximumHeight,
              width: maximumHeight,
              color: Colors.orange,
            );
          }),
      TimeEvent(
        start: DateTime(1702),
        end: DateTime(1860),
        title: "show a bar",
        laneIndex: 3,
        builder: (TimeEvent event, double maximumHeight, double pixelsPerMinute, EventAlignment eventAlignment) {
          return createTimePeriod(
            color: Colors.blueGrey,
            rowHeight: maximumHeight,
            start: event.start,
            end: event.end!,
            pixelsPerMinute: pixelsPerMinute,
            title: event.title,
            eventAlignment: eventAlignment,
          );
        },
      ),
    ],
  ),
);
```
## Additional information
This is a hobby project with no commitment for fixes, updates, or enhancements

Please log issues and suggestions, and feel free to fork, branch, or submit Pull Request on GitHub
