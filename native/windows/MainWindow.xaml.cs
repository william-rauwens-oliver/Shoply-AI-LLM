using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using System;
using System.Collections.ObjectModel;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Windows.Graphics;

namespace LLMChat;

public sealed partial class MainWindow : Window
{
    private AppViewModel _viewModel;

    public MainWindow()
    {
        this.InitializeComponent();
        _viewModel = new AppViewModel();
        this.DataContext = _viewModel;
        
        this.Title = "LLM Chat";
        this.ExtendsContentIntoTitleBar = true;
        
        var presenter = AppWindow.TitleBar;
        presenter.BackgroundColor = Windows.UI.Color.FromArgb(255, 32, 32, 32);
        presenter.ForegroundColor = Windows.UI.Color.FromArgb(255, 255, 255, 255);
        presenter.InactiveBackgroundColor = Windows.UI.Color.FromArgb(255, 32, 32, 32);
        presenter.InactiveForegroundColor = Windows.UI.Color.FromArgb(255, 155, 155, 155);
        
        this.AppWindow.Resize(new SizeInt32(1200, 800));
    }

    private void SendButton_Click(object sender, RoutedEventArgs e)
    {
        _viewModel.SendMessageCommand.Execute(null);
    }

    private void MessageInput_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == Windows.System.VirtualKey.Enter && !_viewModel.IsLoading)
        {
            _viewModel.SendMessageCommand.Execute(null);
            e.Handled = true;
        }
    }
}

public class AppViewModel : INotifyPropertyChanged
{
    private ObservableCollection<ChatMessage> _messages;
    private string _inputText;
    private bool _isLoading;
    private string _selectedModel;
    private float _temperature;
    private string _systemPrompt;
    private string _serverStatus;
    
    private readonly HttpClient _httpClient;
    private const string ApiBaseUrl = "http://127.0.0.1:7860";
    
    public ObservableCollection<ChatMessage> Messages
    {
        get => _messages;
        set { _messages = value; OnPropertyChanged(); }
    }

    public string InputText
    {
        get => _inputText;
        set { _inputText = value; OnPropertyChanged(); }
    }

    public bool IsLoading
    {
        get => _isLoading;
        set { _isLoading = value; OnPropertyChanged(); }
    }

    public string SelectedModel
    {
        get => _selectedModel;
        set { _selectedModel = value; OnPropertyChanged(); }
    }

    public float Temperature
    {
        get => _temperature;
        set { _temperature = value; OnPropertyChanged(); }
    }

    public string SystemPrompt
    {
        get => _systemPrompt;
        set { _systemPrompt = value; OnPropertyChanged(); }
    }

    public string ServerStatus
    {
        get => _serverStatus;
        set { _serverStatus = value; OnPropertyChanged(); }
    }

    public RelayCommand SendMessageCommand { get; }
    public RelayCommand ClearHistoryCommand { get; }

    public AppViewModel()
    {
        _messages = new ObservableCollection<ChatMessage>();
        _inputText = "";
        _isLoading = false;
        _selectedModel = "sshleifer/tiny-gpt2";
        _temperature = 0.8f;
        _systemPrompt = "You are a helpful AI assistant.";
        _serverStatus = "Unknown";
        
        _httpClient = new HttpClient();
        _httpClient.Timeout = TimeSpan.FromSeconds(5);
        
        SendMessageCommand = new RelayCommand(SendMessage, CanSendMessage);
        ClearHistoryCommand = new RelayCommand(ClearHistory);
        
        CheckServerStatus();
        _ = CheckServerStatusPeriodically();
    }

    private void SendMessage()
    {
        if (string.IsNullOrWhiteSpace(InputText) || IsLoading)
            return;

        string userMessage = InputText.Trim();
        InputText = "";
        
        Messages.Add(new ChatMessage 
        { 
            Role = "user", 
            Content = userMessage 
        });

        IsLoading = true;

        _ = SendMessageToServer(userMessage);
    }

    private async Task SendMessageToServer(string message)
    {
        try
        {
            var request = new
            {
                message = message,
                system = SystemPrompt,
                temperature = Temperature,
                model = SelectedModel
            };

            var json = JsonSerializer.Serialize(request);
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync($"{ApiBaseUrl}/api/chat", content);
            
            if (response.IsSuccessStatusCode)
            {
                string responseText = await response.Content.ReadAsStringAsync();
                using JsonDocument doc = JsonDocument.Parse(responseText);
                string assistantResponse = doc.RootElement.GetProperty("response").GetString() ?? "No response";

                MainWindow.DispatcherQueue.TryEnqueue(() =>
                {
                    Messages.Add(new ChatMessage 
                    { 
                        Role = "assistant", 
                        Content = assistantResponse 
                    });
                });
            }
            else
            {
                MainWindow.DispatcherQueue.TryEnqueue(() =>
                {
                    Messages.Add(new ChatMessage 
                    { 
                        Role = "error", 
                        Content = "Error: Server returned " + response.StatusCode 
                    });
                });
            }
        }
        catch (Exception ex)
        {
            MainWindow.DispatcherQueue.TryEnqueue(() =>
            {
                Messages.Add(new ChatMessage 
                { 
                    Role = "error", 
                    Content = $"Error: {ex.Message}" 
                });
            });
        }
        finally
        {
            MainWindow.DispatcherQueue.TryEnqueue(() =>
            {
                IsLoading = false;
            });
        }
    }

    private void ClearHistory()
    {
        Messages.Clear();
    }

    private bool CanSendMessage()
    {
        return !IsLoading && !string.IsNullOrWhiteSpace(InputText);
    }

    private async Task CheckServerStatusPeriodically()
    {
        while (true)
        {
            await Task.Delay(5000);
            CheckServerStatus();
        }
    }

    private void CheckServerStatus()
    {
        _ = Task.Run(async () =>
        {
            try
            {
                var response = await _httpClient.GetAsync($"{ApiBaseUrl}/health");
                var status = response.IsSuccessStatusCode ? "Online" : "Offline";
                
                MainWindow.DispatcherQueue.TryEnqueue(() =>
                {
                    ServerStatus = status;
                });
            }
            catch
            {
                MainWindow.DispatcherQueue.TryEnqueue(() =>
                {
                    ServerStatus = "Offline";
                });
            }
        });
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}

public class ChatMessage
{
    public string Role { get; set; } = "";
    public string Content { get; set; } = "";
    
    public SolidColorBrush BackgroundColor => Role switch
    {
        "user" => new SolidColorBrush(Windows.UI.Color.FromArgb(51, 0, 120, 215)),
        "assistant" => new SolidColorBrush(Windows.UI.Color.FromArgb(31, 128, 128, 128)),
        "error" => new SolidColorBrush(Windows.UI.Color.FromArgb(51, 255, 0, 0)),
        _ => new SolidColorBrush(Windows.UI.Color.FromArgb(31, 200, 200, 0))
    };
}

public class RelayCommand : ICommand
{
    private readonly Action _execute;
    private readonly Func<bool>? _canExecute;

    public event EventHandler? CanExecuteChanged;

    public RelayCommand(Action execute, Func<bool>? canExecute = null)
    {
        _execute = execute;
        _canExecute = canExecute;
    }

    public bool CanExecute(object? parameter) => _canExecute?.Invoke() ?? true;

    public void Execute(object? parameter) => _execute();
}
