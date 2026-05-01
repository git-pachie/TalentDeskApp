namespace GroceryApp.Application.DTOs.UserSettings;

public class UserSettingDto
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
}

public class UpdateUserSettingRequest
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
}

public class NotificationSettingsDto
{
    public bool MarketingPromotions { get; set; }
    public bool ProductUpdates { get; set; }
    public bool NewsAnnouncements { get; set; }
    public bool TransactionsBilling { get; set; } = true;
    public bool AlertsCritical { get; set; } = true;
    public bool UsageActivity { get; set; }
    public bool AccountSecurity { get; set; } = true;
    public bool Reminders { get; set; }
    public bool MessagesSupport { get; set; }
    public bool PersonalizedRecommendations { get; set; }
}
