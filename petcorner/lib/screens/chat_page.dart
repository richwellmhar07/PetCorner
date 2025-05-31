import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final int sellerId;
  final String sellerName;
  final int buyerId;

  const ChatPage({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = []; // List to store chat messages

  // Function to handle sending a message
  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _messages.add("You: ${_messageController.text}");
        _messageController.clear();
      });
    }
  }

  // Confirm Clear Chat
  Future<void> _confirmClearChat() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Chat'),
        content: Text('Are you sure you want to clear the chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _messages.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat cleared successfully')),
      );
    }
  }

  // View Profile
  void _viewProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seller Profile'),
        content: Text('Seller Name: ${widget.sellerName}\nSeller ID: ${widget.sellerId}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Confirm Block User
  Future<void> _confirmBlockUser() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block Seller'),
        content: Text('Are you sure you want to block this seller?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Block'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Here you can add block user logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seller has been blocked')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.sellerName}'),
        backgroundColor: Color.fromARGB(255, 245, 214, 37),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'View Profile') {
                _viewProfile();
              } else if (value == 'Block User') {
                _confirmBlockUser();
              } else if (value == 'Clear Chat') {
                _confirmClearChat();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'View Profile',
                  child: Text('View Profile'),
                ),
                PopupMenuItem(
                  value: 'Block User',
                  child: Text('Block User'),
                ),
                PopupMenuItem(
                  value: 'Clear Chat',
                  child: Text('Clear Chat'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Shop details section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.store, color: Colors.amber),
                    SizedBox(width: 10),
                    Text(
                      'Shop: ${widget.sellerName}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Chat messages list
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: _messages[index].startsWith('You:')
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: _messages[index].startsWith('You:')
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        _messages[index],
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message input field and send button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                    ),
                    onSubmitted: (value) {
                      _sendMessage();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Color.fromARGB(255, 245, 214, 37)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
