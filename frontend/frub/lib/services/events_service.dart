import 'dart:async';
import 'package:flutter/material.dart';

class Event {
  final String id;
  String title;
  String time;
  String location;
  String description;
  Color color;
  bool isPinned;
  bool isAddedToCalendar;
  bool hasRecap;
  String? recap;

  Event({
    required this.id,
    required this.title,
    required this.time,
    required this.location,
    required this.description,
    this.color = Colors.purple,
    this.isPinned = false,
    this.isAddedToCalendar = false,
    this.hasRecap = false,
    this.recap,
  });
}

// Poll Model
class Poll {
  final String id;
  final String question;
  final List<String> options;
  late bool isPinned;
  final DateTime createdAt;
  
  Poll({
    required this.id,
    required this.question,
    required this.options,
    bool isPinned = false,
    required this.createdAt,
  }) : this.isPinned = isPinned;
}

// Form Model
class EventForm {
  final String id;
  final String title;
  final String description;
  late bool isPinned;
  final DateTime createdAt;
  final String prompt; // The form question or prompt
  final List<FormResponse> responses; // Store user responses
  
  EventForm({
    required this.id,
    required this.title,
    required this.description,
    bool isPinned = false,
    required this.createdAt,
    this.prompt = "Please share your feedback:", // Default prompt
    List<FormResponse>? responses,
  }) : 
    this.isPinned = isPinned,
    this.responses = responses ?? [];
}

class FormResponse {
  final String userId;
  final String userName;
  final String answer;
  final DateTime submittedAt;
  
  FormResponse({
    required this.userId,
    required this.userName,
    required this.answer,
    required this.submittedAt,
  });
}

// Service for Events
class EventsService {
  // Singleton pattern
  static final EventsService _instance = EventsService._internal();
  factory EventsService() => _instance;
  EventsService._internal();
  
  // Stream controllers for real-time updates
  final _eventsStreamController = StreamController<Map<DateTime, List<Event>>>.broadcast();
  final _pollsStreamController = StreamController<List<Poll>>.broadcast();
  final _formsStreamController = StreamController<List<EventForm>>.broadcast();
  
  // Stream getters
  Stream<Map<DateTime, List<Event>>> get eventsStream => _eventsStreamController.stream;
  Stream<List<Poll>> get pollsStream => _pollsStreamController.stream;
  Stream<List<EventForm>> get formsStream => _formsStreamController.stream;
  
  // Events data
  final Map<DateTime, List<Event>> events = {};
  
  // Polls data
  final List<Poll> polls = [];
  
  // Forms data
  final List<EventForm> forms = [];
  
  // Initialize with dummy data
  void init() {
    // Only initialize if not already done
    if (events.isNotEmpty || polls.isNotEmpty || forms.isNotEmpty) {
      return;
    }
    
    // Sample events data
    events[DateTime(2025, 3, 5)] = [
      Event(
        id: 'event_001',
        title: 'Team Lunch',
        time: '12:00 PM - 1:30 PM',
        location: 'Downtown Cafe',
        description: 'Monthly team lunch to discuss upcoming initiatives',
        color: Colors.orange,
      ),
    ];
    
    // Sample polls
    polls.add(
      Poll(
        id: 'poll_001',
        question: 'What time works best for the next driver meeting?',
        options: ['Morning (9-11 AM)', 'Afternoon (2-4 PM)', 'Evening (6-8 PM)'],
        isPinned: true,
        createdAt: DateTime(2025, 3, 10),
      ),
    );
    
    // Sample forms
  forms.add(
    EventForm(
      id: 'form_001',
      title: 'Driver Feedback Form',
      description: 'Please share your experience and suggestions for improvement',
      prompt: 'How was your experience with our service?',
      isPinned: true,
      createdAt: DateTime(2025, 3, 12),
    ),
  );
    
    // Notify listeners of initial data
    _notifyListeners();
  }
  
  // Methods to update data
  void addEvent(DateTime date, Event event) {
  // If the event doesn't have a specific color assigned, give it a more visible one
  // Avoid using colors close to the background color
  if (event.color == Colors.purple) {
    // Use a different default color for better visibility
    event.color = Colors.orange; // You can choose any bright color
  }
  if (events[date] != null) {
    events[date]!.add(event);
  } else {
    events[date] = [event];
  }
  _notifyListeners();
}
  
  void toggleEventPin(String eventId) {
    for (var entry in events.entries) {
      for (var event in entry.value) {
        if (event.id == eventId) {
          event.isPinned = !event.isPinned;
          _notifyListeners();
          return;
        }
      }
    }
  }
  
  void toggleEventCalendar(String eventId) {
    for (var entry in events.entries) {
      for (var event in entry.value) {
        if (event.id == eventId) {
          event.isAddedToCalendar = !event.isAddedToCalendar;
          _notifyListeners();
          return;
        }
      }
    }
  }
  
  void addRecapToEvent(String eventId, String recap) {
    for (var entry in events.entries) {
      for (var event in entry.value) {
        if (event.id == eventId) {
          event.hasRecap = true;
          event.recap = recap;
          _notifyListeners();
          return;
        }
      }
    }
  }

  // Method to update an existing event
  void updateEvent(String eventId, {
    String? title,
    String? time,
    String? location,
    String? description,
    Color? color,
  }) {
    for (var entry in events.entries) {
      for (var event in entry.value) {
        if (event.id == eventId) {
          // Update event properties if new values are provided
          if (title != null) event.title = title;
          if (time != null) event.time = time;
          if (location != null) event.location = location;
          if (description != null) event.description = description;
          if (color != null) event.color = color;
          _notifyListeners();
          return;
        }
      }
    }
  }
  
  // Method to delete an event - updated for complete removal
  bool deleteEvent(String eventId) {
    bool eventDeleted = false;
    List<DateTime> datesToRemove = [];
    
    // Loop through all dates
    for (var entry in events.entries) {
      final date = entry.key;
      final eventsList = entry.value;
      
      // Find the event index
      int indexToRemove = -1;
      for (int i = 0; i < eventsList.length; i++) {
        if (eventsList[i].id == eventId) {
          indexToRemove = i;
          break;
        }
      }
      
      // If found, remove it
      if (indexToRemove >= 0) {
        eventsList.removeAt(indexToRemove);
        eventDeleted = true;
        
        // If no more events for this date, mark for removal
        if (eventsList.isEmpty) {
          datesToRemove.add(date);
        }
      }
    }
    
    // Remove any empty dates
    for (var date in datesToRemove) {
      events.remove(date);
    }
    
    // Only notify listeners if something changed
    if (eventDeleted) {
      _notifyListeners();
    }
    
    return eventDeleted;
  }
  
  void addPoll(Poll poll) {
    polls.add(poll);
    _notifyListeners();
  }
  
  void togglePollPin(String pollId) {
    for (var poll in polls) {
      if (poll.id == pollId) {
        poll.isPinned = !poll.isPinned;
        _notifyListeners();
        return;
      }
    }
  }
  
  bool deletePoll(String pollId) {
    final initialLength = polls.length;
    polls.removeWhere((poll) => poll.id == pollId);
    final removed = polls.length < initialLength;
    
    if (removed) {
      _notifyListeners();
    }
    
    return removed;
  }
  
  void addForm(EventForm form) {
    forms.add(form);
    _notifyListeners();
  }
  
  void toggleFormPin(String formId) {
    for (var form in forms) {
      if (form.id == formId) {
        form.isPinned = !form.isPinned;
        _notifyListeners();
        return;
      }
    }
  }
  
  bool deleteForm(String formId) {
    final initialLength = forms.length;
    forms.removeWhere((form) => form.id == formId);
    final removed = forms.length < initialLength;
    
    if (removed) {
      _notifyListeners();
    }
    
    return removed;
  }

  void submitFormResponse(String formId, String userId, String userName, String answer) {
  // Find the form
  final formIndex = forms.indexWhere((form) => form.id == formId);
  if (formIndex >= 0) {
    // Create the response
    final response = FormResponse(
      userId: userId,
      userName: userName,
      answer: answer,
      submittedAt: DateTime.now(),
    );
    
    // Add to the form's responses
    forms[formIndex].responses.add(response);
    
    // Notify listeners
    _notifyListeners();
  }
}
  
  List<Event> getEventsForDay(DateTime day) {
    // Normalize the date to avoid time comparison issues
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return events[normalizedDay] ?? [];
  }
  
  List<MapEntry<DateTime, Event>> getAllEvents() {
    return events.entries
        .expand((entry) => entry.value.map((event) => MapEntry(entry.key, event)))
        .toList();
  }
  
  List<MapEntry<DateTime, Event>> getUpcomingEvents() {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    
    return events.entries
        .where((entry) => entry.key.isAfter(normalizedNow.subtract(const Duration(days: 1))))
        .expand((entry) => entry.value.map((event) => MapEntry(entry.key, event)))
        .toList();
  }
  
  List<MapEntry<DateTime, Event>> getPastEvents() {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    
    return events.entries
        .where((entry) => entry.key.isBefore(normalizedNow))
        .expand((entry) => entry.value.map((event) => MapEntry(entry.key, event)))
        .toList();
  }
  
  List<Event> getPinnedEvents() {
    return events.entries
        .expand((entry) => entry.value)
        .where((event) => event.isPinned)
        .toList();
  }
  
  // Get events with recaps for easy filtering
  List<MapEntry<DateTime, Event>> getEventsWithRecaps() {
    return events.entries
        .expand((entry) => entry.value.map((event) => MapEntry(entry.key, event)))
        .where((entry) => entry.value.hasRecap)
        .toList();
  }

  // In EventsService.dart - Add these methods to get pinned/unpinned polls and forms

// Methods for Polls
List<Poll> getPinnedPolls() {
  return polls.where((poll) => poll.isPinned).toList();
}

List<Poll> getUnpinnedPolls() {
  return polls.where((poll) => !poll.isPinned).toList();
}

// Methods for Forms
List<EventForm> getPinnedForms() {
  return forms.where((form) => form.isPinned).toList();
}

List<EventForm> getUnpinnedForms() {
  return forms.where((form) => !form.isPinned).toList();
}


  
  // Notify all listeners of changes
  void _notifyListeners() {
    _eventsStreamController.add(events);
    _pollsStreamController.add(polls);
    _formsStreamController.add(forms);
  }
  
  // Dispose controllers when service is no longer needed
  void dispose() {
    _eventsStreamController.close();
    _pollsStreamController.close();
    _formsStreamController.close();
  }
}