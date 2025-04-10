import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frub/services/user_service.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/events_service.dart';

class EventsScreen extends StatefulWidget {
  final bool isAdmin;
  
  const EventsScreen({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  final EventsService _eventsService = EventsService();
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _pollsSubscription;
  StreamSubscription? _formsSubscription;
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDay = _focusedDay;
    
    // Initialize event service
    _eventsService.init();
    
    // Subscribe to events changes
    _eventsSubscription = _eventsService.eventsStream.listen((_) {
      if (mounted) {
        setState(() {
          // This will rebuild the UI with the latest events data
        });
      }
    });
    
    // Subscribe to polls changes
    _pollsSubscription = _eventsService.pollsStream.listen((_) {
      if (mounted) {
        setState(() {
          // This will rebuild the UI with the latest polls data
        });
      }
    });
    
    // Subscribe to forms changes
    _formsSubscription = _eventsService.formsStream.listen((_) {
      if (mounted) {
        setState(() {
          // This will rebuild the UI with the latest forms data
        });
      }
    });
  }
  
  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _pollsSubscription?.cancel();
    _formsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

// In EventsScreen.dart - Update _showEventActions method
void _showEventActions(Event event) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Wrap(
      children: [
        ListTile(
          leading: Icon(
            Icons.calendar_today,
            color: event.isAddedToCalendar ? Colors.green : null,
          ),
          title: Text(
            event.isAddedToCalendar 
                ? 'Remove from Calendar' 
                : 'Add to Calendar'
          ),
          onTap: () {
            Navigator.pop(context);
            setState(() {
              _eventsService.toggleEventCalendar(event.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(event.isAddedToCalendar 
                    ? 'Event added to your calendar' 
                    : 'Event removed from your calendar'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        // Show the recap option if the event has one
        if (event.hasRecap)
          ListTile(
            leading: const Icon(Icons.summarize),
            title: const Text('View Event Recap'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('${event.title} - Recap'),
                  content: Text(event.recap ?? 'No recap available'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        // REMOVED: Pin/Unpin option for regular users
        // REMOVED: Edit option for regular users
      ],
    ),
  );
}
// Add these methods to your EventsScreen class

void _showEditEventDialog(Event event) {
  final titleController = TextEditingController(text: event.title);
  final timeController = TextEditingController(text: event.time);
  final locationController = TextEditingController(text: event.location);
  final descriptionController = TextEditingController(text: event.description);
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
              ),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Time (e.g., 3:00 PM - 4:00 PM)',
              ),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _eventsService.updateEvent(
                event.id,
                title: titleController.text.isEmpty ? event.title : titleController.text,
                time: timeController.text.isEmpty ? event.time : timeController.text,
                location: locationController.text.isEmpty ? event.location : locationController.text,
                description: descriptionController.text.isEmpty ? event.description : descriptionController.text,
              );
            });
            
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Event updated successfully'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

// Add a method to show full recap in a dialog
void _showRecapDialog(MapEntry<DateTime, Event> entry) {
  final event = entry.value;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${event.title} - Recap'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Date: ${entry.key.month}/${entry.key.day}/${entry.key.year}'),
            const SizedBox(height: 16),
            Text(event.recap ?? 'No recap available'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showDeleteEventDialog(Event event) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Event'),
      content: Text('Are you sure you want to delete "${event.title}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          onPressed: () {
            setState(() {
              _eventsService.deleteEvent(event.id);
            });
            
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${event.title} deleted'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

  void _showPollVotingDialog(Poll poll) {
    String? selectedOption;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(poll.question),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: poll.options.map((option) => RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() {
                    selectedOption = value;
                  });
                },
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // In a real app, this would submit the vote to the backend
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You voted: ${selectedOption ?? "No option selected"}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  

  // In EventsScreen.dart - Update the form dialog method

void _showFormDetailsDialog(EventForm form) {
  final answerController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isSubmitting = false;
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(form.title),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  form.description,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Text(
                  form.prompt,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: answerController,
                  decoration: const InputDecoration(
                    hintText: 'Type your answer here...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an answer';
                    }
                    return null;
                  },
                ),
                if (isSubmitting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[800],
              foregroundColor: Colors.white,
            ),
            onPressed: isSubmitting 
                ? null 
                : () async {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        isSubmitting = true;
                      });
                      
                      // Get the current user (In a real app, this would be from auth)
                      final userService = UserService();
                      final currentUser = userService.currentUser!;
                      
                      // Submit the form answer
                      _eventsService.submitFormResponse(
                        form.id, 
                        currentUser.email, 
                        currentUser.name.isEmpty ? 'User' : currentUser.name, 
                        answerController.text.trim(),
                      );
                      
                      // Short delay to show processing
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Response submitted successfully'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
            child: const Text('Submit'),
          ),
        ],
      ),
    ),
  );
}
  

// Add a method to show event details in a dialog
void _showEventDetailsDialog(MapEntry<DateTime, Event> entry) {
  final event = entry.value;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(event.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Date: ${entry.key.month}/${entry.key.day}/${entry.key.year}'),
            const SizedBox(height: 8),
            Text('Time: ${event.time}'),
            const SizedBox(height: 8),
            Text('Location: ${event.location}'),
            const SizedBox(height: 16),
            Text('Description:'),
            const SizedBox(height: 4),
            Text(event.description),
            if (event.hasRecap) ...[
              const SizedBox(height: 16),
              const Text(
                'Recap:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(event.recap ?? ''),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}



  Widget build(BuildContext context) {
    print('EventsScreen - Total events: ${_eventsService.getAllEvents().length}');
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 78, 14, 89),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Events'),
      backgroundColor: Colors.purple[800],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,              // Active tab text color
        unselectedLabelColor: Colors.white70,  // Inactive tab text color (optional)
        tabs: const [
          Tab(text: 'Calendar'),
          Tab(text: 'Events List'),
          Tab(text: 'Polls & Forms'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: [
          // Calendar Tab
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2025, 1, 1),
                      lastDay: DateTime.utc(2025, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
                      eventLoader: _eventsService.getEventsForDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        markersMaxCount: 3,
                        markerDecoration: const BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _selectedDay == null 
                              ? 'Events' 
                              : 'Events for ${_selectedDay!.month}/${_selectedDay!.day}/${_selectedDay!.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Expanded(
                      child: _selectedDay == null 
                          ? const Center(child: Text('Select a day to view events'))
                          : _eventsService.getEventsForDay(_selectedDay!).isEmpty
                              ? const Center(child: Text('No events for this date'))
                              : ListView.builder(
                                  itemCount: _eventsService.getEventsForDay(_selectedDay!).length,
                                  itemBuilder: (context, index) {
                                    final event = _eventsService.getEventsForDay(_selectedDay!)[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, 
                                        vertical: 4.0,
                                      ),
                                      child: Card(
                                        elevation: 2,
                                        color: event.color.withOpacity(0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(
                                            color: event.color,
                                            width: 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.event,
                                            color: event.color,
                                          ),
                                          title: Text(event.title),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${event.time}\n${event.location}'),
                                              if (event.hasRecap) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.summarize, size: 12, color: Colors.blue),
                                                    const SizedBox(width: 4),
                                                    GestureDetector(
                                                      onTap: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) => AlertDialog(
                                                            title: Text('${event.title} - Recap'),
                                                            content: Text(event.recap ?? 'No recap available'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(context),
                                                                child: const Text('Close'),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                      child: const Text(
                                                        'View Recap',
                                                        style: TextStyle(
                                                          color: Colors.blue,
                                                          fontSize: 12,
                                                          decoration: TextDecoration.underline,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (event.isPinned)
                                                const Icon(
                                                  Icons.push_pin,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                              if (event.isAddedToCalendar)
                                                const SizedBox(width: 4),
                                              if (event.isAddedToCalendar)
                                                const Icon(
                                                  Icons.calendar_today,
                                                  color: Colors.blue,
                                                  size: 16,
                                                ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                iconSize: 16,
                                                icon: const Icon(Icons.info_outline),
                                                onPressed: () => _showEventActions(event),
                                              ),
                                            ],
                                          ),
                                          isThreeLine: true,
                                          onTap: () => _showEventActions(event),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    if (_selectedDay != null && _eventsService.getEventsForDay(_selectedDay!).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              final event = _eventsService.getEventsForDay(_selectedDay!).first;
                              setState(() {
                                _eventsService.toggleEventCalendar(event.id);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    event.isAddedToCalendar
                                        ? 'Event added to calendar'
                                        : 'Event removed from calendar'
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Text(
                              _eventsService.getEventsForDay(_selectedDay!).first.isAddedToCalendar
                                  ? 'Remove Event from Calendar'
                                  : 'Add Event to Calendar'
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Events List Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Events',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                // Pinned Events Section
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.push_pin, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Pinned Events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: _eventsService.getPinnedEvents().isEmpty
                      ? const Center(
                          child: Text(
                            'No pinned events',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          children: _eventsService.getPinnedEvents()
                              .map((event) => Container(
                                    width: 200,
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Card(
                                      elevation: 4,
                                      color: event.color.withOpacity(0.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: event.color, width: 1),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              event.time,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            const Spacer(),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  event.location,
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                                IconButton(
                                                  iconSize: 16,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: const Icon(Icons.info_outline),
                                                  onPressed: () => _showEventActions(event),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
                
                // Upcoming Events Section
                const SizedBox(height: 16),
                const Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _eventsService.getUpcomingEvents().isEmpty
                      ? const Center(
                          child: Text(
                            'No upcoming events',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView(
                          children: _eventsService.getUpcomingEvents()
                              .map((entry) => Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  entry.value.title,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (entry.value.isPinned)
                                                const Icon(
                                                  Icons.push_pin,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 16),
                                              const SizedBox(width: 4),
                                              Text('${entry.key.month}/${entry.key.day}/${entry.key.year}'),
                                              const SizedBox(width: 16),
                                              const Icon(Icons.access_time, size: 16),
                                              const SizedBox(width: 4),
                                              Text(entry.value.time),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 16),
                                              const SizedBox(width: 4),
                                              Text(entry.value.location),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            entry.value.description,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          // Show recap indicator if available
                                          if (entry.value.hasRecap) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.summarize, size: 16, color: Colors.blue),
                                                const SizedBox(width: 4),
                                                TextButton(
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: Text('${entry.value.title} - Recap'),
                                                        content: Text(entry.value.recap ?? 'No recap available'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('Close'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                  child: const Text('View Event Recap'),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          // In the Events List tab, update the trailing buttons for events
// Replace the existing Pin/Unpin TextButton with just a View button
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    TextButton.icon(
      icon: Icon(
        Icons.calendar_today,
        color: entry.value.isAddedToCalendar 
            ? Colors.green 
            : null,
        size: 16,
      ),
      label: Text(
        entry.value.isAddedToCalendar 
            ? 'Added' 
            : 'Add'
      ),
      onPressed: () {
        setState(() {
          _eventsService.toggleEventCalendar(entry.value.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              entry.value.isAddedToCalendar 
                  ? 'Added to calendar' 
                  : 'Removed from calendar'
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    ),
    // REMOVED: Pin/Unpin button
    TextButton.icon(
      icon: const Icon(Icons.visibility, size: 16),
      label: const Text('View'),
      onPressed: () => _showEventActions(entry.value),
    ),
  ],
),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
                
                // Add Event Recaps Section
                const SizedBox(height: 24),
                if (_eventsService.getEventsWithRecaps().isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.summarize, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Event Recaps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _eventsService.getEventsWithRecaps()
                          .map((entry) => Container(
                                width: 250,
                                margin: const EdgeInsets.only(right: 16),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.value.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${entry.key.month}/${entry.key.day}/${entry.key.year}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Recap:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          entry.value.recap ?? '',
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Spacer(),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: Text('${entry.value.title} - Recap'),
                                                  content: Text(entry.value.recap ?? 'No recap available'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('Close'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            child: const Text('Read More'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Polls & Forms Tab (Updated to include pinned sections)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Polls & Forms',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                // Pinned Polls Section
                if (_eventsService.getPinnedPolls().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.push_pin, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Pinned Polls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._eventsService.getPinnedPolls().map((poll) => _buildPollCard(poll)),
                ],
                
                // Regular Polls Section
                const SizedBox(height: 24),
                const Text(
                  'Polls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (_eventsService.getUnpinnedPolls().isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No polls available',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  ..._eventsService.getUnpinnedPolls().map((poll) => _buildPollCard(poll)),
                
                // Pinned Forms Section
                if (_eventsService.getPinnedForms().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.push_pin, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Pinned Forms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._eventsService.getPinnedForms().map((form) => _buildFormCard(form)),
                ],
                
                // Regular Forms Section
                const SizedBox(height: 24),
                const Text(
                  'Forms',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (_eventsService.getUnpinnedForms().isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No forms available',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  ..._eventsService.getUnpinnedForms().map((form) => _buildFormCard(form)),
                const SizedBox(height: 100), // Add padding at the bottom
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper methods for building card widgets
Widget _buildPollCard(Poll poll) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  poll.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (poll.isPinned)
                const Icon(
                  Icons.push_pin,
                  color: Colors.red,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created on: ${poll.createdAt.month}/${poll.createdAt.day}/${poll.createdAt.year}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showPollVotingDialog(poll),
              child: const Text('Vote'),
            ),
          ),
        ],
      ),
    ),
  );
}

// Update the Event Recap card
Widget _buildRecapCard(MapEntry<DateTime, Event> entry) {
  final event = entry.value;
  
  return Card(
    margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${entry.key.month}/${entry.key.day}/${entry.key.year}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recap:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            event.recap ?? '',
            maxLines: 2, // Limit to 2 lines
            overflow: TextOverflow.ellipsis,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Show full recap in a dialog
                _showRecapDialog(entry);
              },
              child: const Text('Read More'),
            ),
          ),
        ],
      ),
    ),
  );
}

// Update the event card in EventsScreen and EventsAdminScreen
Widget _buildEventCard(MapEntry<DateTime, Event> entry) {
  final event = entry.value;
  
  return Card(
    margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
    elevation: 4,
    // Use different colors based on the source of the event
    color: event.color.withOpacity(0.2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: event.color,
        width: 2,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event title - make sure it wraps properly
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2, // Limit to 2 lines
                  overflow: TextOverflow.ellipsis, // Add ellipsis if it overflows
                ),
              ),
              if (event.isPinned)
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Icon(
                    Icons.push_pin,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Time - make sure it fits
          Text(
            event.time,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Location - make sure it fits
          Text(
            event.location,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Only show info button for more details
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: () {
                // Show detailed event info in a dialog
                _showEventDetailsDialog(entry);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildFormCard(EventForm form) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  form.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (form.isPinned)
                const Icon(
                  Icons.push_pin,
                  color: Colors.red,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            form.description,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Created on: ${form.createdAt.month}/${form.createdAt.day}/${form.createdAt.year}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showFormDetailsDialog(form),
              child: const Text('Open Form'),
            ),
          ),
        ],
      ),
    ),
  );
  
}
}