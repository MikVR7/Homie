# Frontend Integration Guide - Drive Management

## Question 1: Correct API Endpoint for Drive Availability

### The Issue
You're trying to use: `PUT /api/file-organizer/drives/{drive_id}/availability` ❌

### The Correct Endpoint
Use: `PUT /api/file-organizer/drives/availability` ✅

**Important**: The endpoint does NOT use `drive_id` in the URL. Instead, it uses `unique_identifier` in the request body.

### Correct Request Format

```http
PUT /api/file-organizer/drives/availability
Content-Type: application/json

{
  "user_id": "your_user_id",
  "client_id": "your_client_id",
  "unique_identifier": "USB-SERIAL-12345",
  "is_available": false
}
```

### C# Example (Avalonia)

```csharp
public async Task UpdateDriveAvailability(string uniqueIdentifier, bool isAvailable)
{
    var request = new
    {
        user_id = _userId,
        client_id = _clientId,
        unique_identifier = uniqueIdentifier,
        is_available = isAvailable
    };

    var response = await _httpClient.PutAsJsonAsync(
        "/api/file-organizer/drives/availability",
        request
    );

    if (response.IsSuccessStatusCode)
    {
        var result = await response.Content.ReadFromJsonAsync<ApiResponse>();
        Console.WriteLine($"Drive availability updated: {result.Success}");
    }
    else
    {
        Console.WriteLine($"Failed to update drive: {response.StatusCode}");
    }
}

// When drive is disconnected
await UpdateDriveAvailability("USB-SERIAL-12345", false);

// When drive is reconnected
await UpdateDriveAvailability("USB-SERIAL-12345", true);
```

### Response Format

**Success (200 OK)**:
```json
{
  "success": true,
  "message": "Drive availability updated"
}
```

**Error (404 Not Found)**:
```json
{
  "success": false,
  "error": "Drive not found"
}
```

**Error (400 Bad Request)**:
```json
{
  "success": false,
  "error": "unique_identifier is required"
}
```

---

## Question 2: Better Alternative to Polling

### Current Problem
Polling every 5 seconds is inefficient:
- Wastes bandwidth
- Increases server load
- Battery drain on laptops
- Delayed updates (up to 5 seconds)

### Solution 1: WebSocket for Real-Time Updates (RECOMMENDED)

I'll implement a WebSocket endpoint for real-time drive updates. This is the best solution for your use case.

#### Backend WebSocket Implementation

```python
# backend/core/routes/drive_websocket.py
from flask_sock import Sock
import json
import logging

logger = logging.getLogger('DriveWebSocket')

def register_drive_websocket(app, web_server):
    """Register WebSocket endpoint for real-time drive updates"""
    sock = Sock(app)
    
    # Store active WebSocket connections per user
    active_connections = {}
    
    @sock.route('/ws/file-organizer/drives')
    def drive_updates(ws):
        """WebSocket endpoint for drive updates"""
        user_id = None
        client_id = None
        
        try:
            # Wait for initial handshake
            data = ws.receive()
            handshake = json.loads(data)
            user_id = handshake.get('user_id', 'dev_user')
            client_id = handshake.get('client_id', 'default_client')
            
            # Store connection
            if user_id not in active_connections:
                active_connections[user_id] = {}
            active_connections[user_id][client_id] = ws
            
            logger.info(f"WebSocket connected: {user_id}/{client_id}")
            
            # Send initial drive list
            drive_manager = web_server.app_manager.get_module('file_organizer').path_memory_manager._drive_manager
            drives = drive_manager.get_drives(user_id)
            
            ws.send(json.dumps({
                'type': 'initial',
                'drives': [drive_to_dict(d) for d in drives]
            }))
            
            # Keep connection alive and listen for messages
            while True:
                data = ws.receive()
                if data:
                    message = json.loads(data)
                    
                    # Handle drive update from client
                    if message.get('type') == 'update':
                        unique_id = message.get('unique_identifier')
                        is_available = message.get('is_available')
                        
                        success = drive_manager.update_drive_availability(
                            user_id, unique_id, is_available, client_id
                        )
                        
                        if success:
                            # Broadcast to all clients of this user
                            broadcast_drive_update(user_id, unique_id, is_available, client_id)
                        
        except Exception as e:
            logger.error(f"WebSocket error: {e}")
        finally:
            # Clean up connection
            if user_id and client_id:
                if user_id in active_connections:
                    active_connections[user_id].pop(client_id, None)
                logger.info(f"WebSocket disconnected: {user_id}/{client_id}")
    
    def broadcast_drive_update(user_id, unique_identifier, is_available, source_client_id):
        """Broadcast drive update to all connected clients"""
        if user_id in active_connections:
            message = json.dumps({
                'type': 'drive_update',
                'unique_identifier': unique_identifier,
                'is_available': is_available,
                'source_client_id': source_client_id
            })
            
            for client_id, ws in active_connections[user_id].items():
                try:
                    ws.send(message)
                except Exception as e:
                    logger.error(f"Failed to send to {client_id}: {e}")

def drive_to_dict(drive):
    """Convert Drive object to dictionary"""
    return {
        'id': drive.id,
        'unique_identifier': drive.unique_identifier,
        'mount_point': drive.mount_point,
        'volume_label': drive.volume_label,
        'drive_type': drive.drive_type,
        'is_available': drive.is_available
    }
```

#### C# WebSocket Client (Avalonia)

```csharp
using System;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

public class DriveWebSocketClient : IDisposable
{
    private ClientWebSocket _webSocket;
    private CancellationTokenSource _cancellationTokenSource;
    private readonly string _baseUrl;
    private readonly string _userId;
    private readonly string _clientId;
    
    public event EventHandler<DriveUpdateEventArgs> DriveUpdated;
    public event EventHandler<List<Drive>> InitialDrivesReceived;
    
    public DriveWebSocketClient(string baseUrl, string userId, string clientId)
    {
        _baseUrl = baseUrl;
        _userId = userId;
        _clientId = clientId;
    }
    
    public async Task ConnectAsync()
    {
        _webSocket = new ClientWebSocket();
        _cancellationTokenSource = new CancellationTokenSource();
        
        var wsUrl = _baseUrl.Replace("http://", "ws://").Replace("https://", "wss://");
        var uri = new Uri($"{wsUrl}/ws/file-organizer/drives");
        
        await _webSocket.ConnectAsync(uri, _cancellationTokenSource.Token);
        
        // Send handshake
        var handshake = new
        {
            user_id = _userId,
            client_id = _clientId
        };
        await SendMessageAsync(handshake);
        
        // Start listening for messages
        _ = Task.Run(ListenForMessagesAsync);
    }
    
    private async Task ListenForMessagesAsync()
    {
        var buffer = new byte[4096];
        
        while (_webSocket.State == WebSocketState.Open)
        {
            try
            {
                var result = await _webSocket.ReceiveAsync(
                    new ArraySegment<byte>(buffer),
                    _cancellationTokenSource.Token
                );
                
                if (result.MessageType == WebSocketMessageType.Text)
                {
                    var message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                    HandleMessage(message);
                }
                else if (result.MessageType == WebSocketMessageType.Close)
                {
                    await _webSocket.CloseAsync(
                        WebSocketCloseStatus.NormalClosure,
                        "Closing",
                        CancellationToken.None
                    );
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"WebSocket error: {ex.Message}");
                break;
            }
        }
    }
    
    private void HandleMessage(string message)
    {
        var doc = JsonDocument.Parse(message);
        var root = doc.RootElement;
        var type = root.GetProperty("type").GetString();
        
        switch (type)
        {
            case "initial":
                var drives = JsonSerializer.Deserialize<List<Drive>>(
                    root.GetProperty("drives").GetRawText()
                );
                InitialDrivesReceived?.Invoke(this, drives);
                break;
                
            case "drive_update":
                var uniqueId = root.GetProperty("unique_identifier").GetString();
                var isAvailable = root.GetProperty("is_available").GetBoolean();
                var sourceClientId = root.GetProperty("source_client_id").GetString();
                
                DriveUpdated?.Invoke(this, new DriveUpdateEventArgs
                {
                    UniqueIdentifier = uniqueId,
                    IsAvailable = isAvailable,
                    SourceClientId = sourceClientId
                });
                break;
        }
    }
    
    public async Task NotifyDriveChangeAsync(string uniqueIdentifier, bool isAvailable)
    {
        var message = new
        {
            type = "update",
            unique_identifier = uniqueIdentifier,
            is_available = isAvailable
        };
        
        await SendMessageAsync(message);
    }
    
    private async Task SendMessageAsync(object message)
    {
        var json = JsonSerializer.Serialize(message);
        var bytes = Encoding.UTF8.GetBytes(json);
        
        await _webSocket.SendAsync(
            new ArraySegment<byte>(bytes),
            WebSocketMessageType.Text,
            true,
            _cancellationTokenSource.Token
        );
    }
    
    public void Dispose()
    {
        _cancellationTokenSource?.Cancel();
        _webSocket?.Dispose();
    }
}

public class DriveUpdateEventArgs : EventArgs
{
    public string UniqueIdentifier { get; set; }
    public bool IsAvailable { get; set; }
    public string SourceClientId { get; set; }
}

// Usage in your Avalonia app
public class DriveService
{
    private DriveWebSocketClient _wsClient;
    
    public async Task InitializeAsync()
    {
        _wsClient = new DriveWebSocketClient(
            "http://localhost:5000",
            "user123",
            "laptop1"
        );
        
        _wsClient.InitialDrivesReceived += (sender, drives) =>
        {
            Console.WriteLine($"Received {drives.Count} drives");
            // Update UI with initial drives
        };
        
        _wsClient.DriveUpdated += (sender, args) =>
        {
            Console.WriteLine($"Drive {args.UniqueIdentifier} is now {(args.IsAvailable ? "available" : "unavailable")}");
            // Update UI with drive change
        };
        
        await _wsClient.ConnectAsync();
    }
    
    // When you detect a drive was disconnected
    public async Task OnDriveDisconnected(string uniqueIdentifier)
    {
        await _wsClient.NotifyDriveChangeAsync(uniqueIdentifier, false);
    }
    
    // When you detect a drive was connected
    public async Task OnDriveConnected(string uniqueIdentifier)
    {
        await _wsClient.NotifyDriveChangeAsync(uniqueIdentifier, true);
    }
}
```

### Solution 2: Optimized Polling (If WebSocket Not Possible)

If you can't use WebSocket, optimize your polling:

```csharp
public class OptimizedDrivePoller
{
    private readonly HttpClient _httpClient;
    private Timer _timer;
    private string _lastDrivesHash;
    
    // Adaptive polling: start at 30 seconds, reduce to 10 seconds when changes detected
    private int _currentInterval = 30000; // 30 seconds
    private const int FastInterval = 10000; // 10 seconds
    private const int SlowInterval = 30000; // 30 seconds
    
    public async Task StartPollingAsync()
    {
        _timer = new Timer(async _ => await PollDrivesAsync(), null, 0, _currentInterval);
    }
    
    private async Task PollDrivesAsync()
    {
        try
        {
            var response = await _httpClient.GetAsync("/api/file-organizer/drives?user_id=user123");
            var json = await response.Content.ReadAsStringAsync();
            var currentHash = ComputeHash(json);
            
            if (currentHash != _lastDrivesHash)
            {
                // Drives changed - process update
                var result = JsonSerializer.Deserialize<DrivesResponse>(json);
                OnDrivesChanged(result.Drives);
                
                // Speed up polling temporarily
                _currentInterval = FastInterval;
                _timer.Change(0, FastInterval);
                
                // Slow down after 2 minutes of no changes
                _ = Task.Delay(120000).ContinueWith(_ =>
                {
                    _currentInterval = SlowInterval;
                    _timer.Change(0, SlowInterval);
                });
            }
            
            _lastDrivesHash = currentHash;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Polling error: {ex.Message}");
        }
    }
    
    private string ComputeHash(string input)
    {
        using var sha256 = System.Security.Cryptography.SHA256.Create();
        var bytes = Encoding.UTF8.GetBytes(input);
        var hash = sha256.ComputeHash(bytes);
        return Convert.ToBase64String(hash);
    }
}
```

### Solution 3: Event-Driven with OS Notifications

Use OS-level drive detection instead of polling:

```csharp
using System.Management; // Add System.Management.dll reference

public class DriveMonitor
{
    private ManagementEventWatcher _watcher;
    
    public event EventHandler<DriveEventArgs> DriveConnected;
    public event EventHandler<DriveEventArgs> DriveDisconnected;
    
    public void StartMonitoring()
    {
        // Monitor for drive arrival
        var arrivalQuery = new WqlEventQuery("SELECT * FROM Win32_VolumeChangeEvent WHERE EventType = 2");
        _watcher = new ManagementEventWatcher(arrivalQuery);
        _watcher.EventArrived += OnDriveArrived;
        _watcher.Start();
        
        // Monitor for drive removal
        var removalQuery = new WqlEventQuery("SELECT * FROM Win32_VolumeChangeEvent WHERE EventType = 3");
        var removalWatcher = new ManagementEventWatcher(removalQuery);
        removalWatcher.EventArrived += OnDriveRemoved;
        removalWatcher.Start();
    }
    
    private async void OnDriveArrived(object sender, EventArrivedEventArgs e)
    {
        var driveName = e.NewEvent.Properties["DriveName"].Value.ToString();
        Console.WriteLine($"Drive connected: {driveName}");
        
        // Notify backend immediately
        await NotifyBackendDriveConnected(driveName);
        
        DriveConnected?.Invoke(this, new DriveEventArgs { DriveName = driveName });
    }
    
    private async void OnDriveRemoved(object sender, EventArrivedEventArgs e)
    {
        var driveName = e.NewEvent.Properties["DriveName"].Value.ToString();
        Console.WriteLine($"Drive disconnected: {driveName}");
        
        // Notify backend immediately
        await NotifyBackendDriveDisconnected(driveName);
        
        DriveDisconnected?.Invoke(this, new DriveEventArgs { DriveName = driveName });
    }
}
```

---

## Recommended Approach

**Best Solution**: Combine OS-level monitoring with WebSocket

1. Use OS events to detect drive changes immediately
2. Use WebSocket to sync state with backend and other clients
3. No polling needed!

```csharp
public class DriveManager
{
    private DriveMonitor _osMonitor;
    private DriveWebSocketClient _wsClient;
    
    public async Task InitializeAsync()
    {
        // Connect to WebSocket for real-time sync
        _wsClient = new DriveWebSocketClient("http://localhost:5000", "user123", "laptop1");
        await _wsClient.ConnectAsync();
        
        // Monitor OS-level drive events
        _osMonitor = new DriveMonitor();
        _osMonitor.DriveConnected += async (s, e) =>
        {
            await _wsClient.NotifyDriveChangeAsync(e.UniqueIdentifier, true);
        };
        _osMonitor.DriveDisconnected += async (s, e) =>
        {
            await _wsClient.NotifyDriveChangeAsync(e.UniqueIdentifier, false);
        };
        _osMonitor.StartMonitoring();
    }
}
```

---

## Summary

### Answer 1: Correct Endpoint
```
PUT /api/file-organizer/drives/availability
Body: { "unique_identifier": "...", "is_available": false }
```

### Answer 2: Better Than Polling
1. **WebSocket** (Best) - Real-time, bidirectional, efficient
2. **Optimized Polling** (Good) - Adaptive intervals, hash-based change detection
3. **OS Events + WebSocket** (Perfect) - Immediate detection + sync across clients

Let me know if you'd like me to implement the WebSocket endpoint on the backend!
