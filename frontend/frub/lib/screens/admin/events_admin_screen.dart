import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/events_service.dart';

class EventsAdminScreen extends StatefulWidget {
  const EventsAdminScreen({super.key});

  @override
  State<EventsAdminScreen> createState() => _EventsAdminScreenState();
}

class _EventsAdminScreenState extends State<EventsAdminScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  final EventsService _eventsService = EventsService();
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _pollsSubscription;
  StreamSubscription? _formsSubscription;
  
  
   @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
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

 // In EventsAdminScreen.dart - update the _showAddEventDialog method
void _showAddEventDialog() {
  final titleController = TextEditingController();
  final timeController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  Color selectedColor = Colors.orange; // Default to orange instead of purple
  
  final colorOptions = [
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.cyan,
  ];
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add New Event'),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Event Date: '),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Text(
                      '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Event Color:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colorOptions.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
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
              final newEvent = Event(
                id: 'event_${DateTime.now().millisecondsSinceEpoch}',
                title: titleController.text.isNotEmpty 
                    ? titleController.text 
                    : 'New Event',
                time: timeController.text.isNotEmpty 
                    ? timeController.text 
                    : 'TBD',
                location: locationController.text.isNotEmpty 
                    ? locationController.text 
                    : 'TBD',
                description: descriptionController.text.isNotEmpty 
                    ? descriptionController.text 
                    : 'No description provided',
                color: selectedColor, // Use the selected color
              );
              
              _eventsService.addEvent(selectedDate, newEvent);
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Event added successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}

  void _showCreatePollDialog() {
    final titleController = TextEditingController();
    final optionsController = TextEditingController();
    bool isPinned = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Poll Question',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: optionsController,
                  decoration: const InputDecoration(
                    labelText: 'Options (one per line)',
                    hintText: 'Enter each option on a new line',
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isPinned,
                      onChanged: (value) {
                        setState(() => isPinned = value ?? false);
                      },
                    ),
                    const Text('Pin to Events'),
                  ],
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
                final newPoll = Poll(
                  id: 'poll_${DateTime.now().millisecondsSinceEpoch}',
                  question: titleController.text.isNotEmpty 
                      ? titleController.text 
                      : 'New Poll',
                  options: optionsController.text.split('\n')
                      .where((option) => option.trim().isNotEmpty)
                      .toList(),
                  isPinned: isPinned,
                  createdAt: DateTime.now(),
                );
                
                _eventsService.addPoll(newPoll);
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isPinned 
                        ? 'Poll created and pinned to events' 
                        : 'Poll created successfully'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFormDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPinned = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Form'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Form Title',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isPinned,
                      onChanged: (value) {
                        setState(() => isPinned = value ?? false);
                      },
                    ),
                    const Text('Pin to Events'),
                  ],
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
                final newForm = EventForm(
                  id: 'form_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text.isNotEmpty 
                      ? titleController.text 
                      : 'New Form',
                  description: descriptionController.text.isNotEmpty 
                      ? descriptionController.text 
                      : 'No description provided',
                  isPinned: isPinned,
                  createdAt: DateTime.now(),
                );
                
                _eventsService.addForm(newForm);
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isPinned 
                        ? 'Form created and pinned to events' 
                        : 'Form created successfully'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRecapDialog(Event event) {
    final recapController = TextEditingController(text: event.recap);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Recap for ${event.title}'),
        content: TextField(
          controller: recapController,
          decoration: const InputDecoration(
            labelText: 'Event Recap',
            hintText: 'Summarize what happened at the event...',
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _eventsService.addRecapToEvent(event.id, recapController.text);
              });
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recap added successfully'),
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

  // In EventsAdminScreen.dart - Update the _showEditEventDialog to ensure proper state update
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
            _eventsService.updateEvent(
              event.id,
              title: titleController.text.isEmpty ? event.title : titleController.text,
              time: timeController.text.isEmpty ? event.time : timeController.text,
              location: locationController.text.isEmpty ? event.location : locationController.text,
              description: descriptionController.text.isEmpty ? event.description : descriptionController.text,
            );
            
            Navigator.pop(context);
            
            // Force UI update after editing
            setState(() {});
            
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

  // In EventsAdminScreen.dart - Update the _showDeleteEventDialog to ensure proper state update
 // Update the delete button handler
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
              final wasDeleted = _eventsService.deleteEvent(event.id);
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(wasDeleted
                      ? '${event.title} deleted'
                      : 'Error: Could not delete event'),
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

// In EventsAdminScreen.dart - Add method to view form responses

void _showFormResponsesDialog(EventForm form) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${form.title} - Responses (${form.responses.length})'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: form.responses.isEmpty
            ? const Center(
                child: Text('No responses yet'),
              )
            : ListView.separated(
                itemCount: form.responses.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final response = form.responses[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            response.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDateTime(response.submittedAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(response.answer),
                    ],
                  );
                },
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

// Helper method to format date time - place it here
  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day} at $hour:$minute $period';
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

// Update the _buildFormCard method to include a "View Responses" button
Widget _buildFormCard(EventForm form) {
  return Card(
    // ... existing card code ...
    child: Column(
      // ... existing column code ...
      children: [
        // ... existing children ...
       const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.message),
              label: Text('Responses (${form.responses.length})'),
              onPressed: () => _showFormResponsesDialog(form),
            ),
            // ... existing buttons (Edit, Pin/Unpin, Delete) ...
          ],
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
  // Debug print to check if events are the same
  print('EventsAdminScreen - Total events: ${_eventsService.getAllEvents().length}');
 return Scaffold(
      backgroundColor: const Color.fromARGB(255, 78, 14, 89),
      appBar: AppBar(
        title: const Text('Event Administration'),
        backgroundColor: Colors.purple[800],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,              // Active tab text color
          unselectedLabelColor: Colors.white70,  // Inactive tab text color (optional)
          tabs: const [
            Tab(text: 'Manage Events'),
            Tab(text: 'Polls & Forms'),
            Tab(text: 'Event Recaps'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Event',
            onPressed: _showAddEventDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Manage Events Tab
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
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: _eventsService.getAllEvents().map((entry) => Card(
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
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                  onPressed: () => _showEditEventDialog(entry.value),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.push_pin),
                                  label: Text(entry.value.isPinned ? 'Unpin' : 'Pin'),
                                  onPressed: () {
                                    setState(() {
                                      _eventsService.toggleEventPin(entry.value.id);
                                    });
                                  },
                                ),
                                TextButton.icon(
  icon: const Icon(Icons.delete),
  label: const Text('Delete'),
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${entry.value.title}"?'),
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
              // Store the event ID before deletion
              final eventId = entry.value.id;
              final eventTitle = entry.value.title;
              
              // Attempt to delete the event
              final wasDeleted = _eventsService.deleteEvent(eventId);
              
              // Close the dialog
              Navigator.pop(context);
              
              if (wasDeleted) {
                // Force UI update
                setState(() {
                  // This empty setState forces a rebuild
                });
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$eventTitle deleted'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: Could not delete $eventTitle'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  },
),

                              ],
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Polls & Forms Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Polls',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create Poll'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[800],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _showCreatePollDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _eventsService.polls.isEmpty
                      ? const Center(
                          child: Text(
                            'No polls created yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _eventsService.polls.length,
                          itemBuilder: (context, index) {
                            final poll = _eventsService.polls[index];
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
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(Icons.bar_chart),
                                          label: const Text('Results'),
                                          onPressed: () {
                                            // Show poll results (placeholder)
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Poll results functionality coming soon'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.push_pin),
                                          label: Text(poll.isPinned ? 'Unpin' : 'Pin'),
                                          onPressed: () {
                                            setState(() {
                                              _eventsService.togglePollPin(poll.id);
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(poll.isPinned 
                                                    ? 'Poll unpinned' 
                                                    : 'Poll pinned'),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.delete),
                                          label: const Text('Delete'),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Poll'),
                                                content: Text('Are you sure you want to delete this poll?'),
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
                                                        _eventsService.deletePoll(poll.id);
                                                      });
                                                      
                                                      Navigator.pop(context);
                                                      
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Poll deleted'),
                                                          duration: Duration(seconds: 2),
                                                        ),
                                                      );
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Forms',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create Form'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[800],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _showCreateFormDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _eventsService.forms.isEmpty
                      ? const Center(
                          child: Text(
                            'No forms created yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _eventsService.forms.length,
                          itemBuilder: (context, index) {
                            final form = _eventsService.forms[index];
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
                                    Text(form.description),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Created on: ${form.createdAt.month}/${form.createdAt.day}/${form.createdAt.year}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Edit'),
                                          onPressed: () {
                                            // Edit form (placeholder)
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Edit form functionality coming soon'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.push_pin),
                                          label: Text(form.isPinned ? 'Unpin' : 'Pin'),
                                          onPressed: () {
                                            setState(() {
                                              _eventsService.toggleFormPin(form.id);
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(form.isPinned 
                                                    ? 'Form unpinned' 
                                                    : 'Form pinned'),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.delete),
                                          label: const Text('Delete'),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Form'),
                                                content: Text('Are you sure you want to delete this form?'),
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
                                                        _eventsService.deleteForm(form.id);
                                                      });
                                                      
                                                      Navigator.pop(context);
                                                      
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Form deleted'),
                                                          duration: Duration(seconds: 2),
                                                        ),
                                                      );
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // Event Recaps Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event Recaps',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Past Events for Recaps
                Expanded(
                  child: _eventsService.getPastEvents().isEmpty
                      ? const Center(
                          child: Text(
                            'No past events to recap',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView(
                          children: _eventsService.getPastEvents().map((entry) => Card(
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
                                      if (entry.value.hasRecap)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 20,
                                        )
                                      else
                                        const Icon(
                                          Icons.pending,
                                          color: Colors.orange,
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
                                  if (entry.value.hasRecap) ...[
                                    const Text(
                                      'Recap:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(entry.value.recap ?? ''),
                                    const SizedBox(height: 8),
                                  ],
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: Icon(
                                          entry.value.hasRecap ? Icons.edit : Icons.add,
                                        ),
                                        label: Text(
                                          entry.value.hasRecap ? 'Edit Recap' : 'Add Recap',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple[800],
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => _showAddRecapDialog(entry.value),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Add Event'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddEventDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.poll),
                  title: const Text('Create Poll'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreatePollDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Create Form'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateFormDialog();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}