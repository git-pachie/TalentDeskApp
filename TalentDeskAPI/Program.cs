using TalentDeskAPI.Configuration;
using TalentDeskAPI.Services;

var builder = WebApplication.CreateBuilder(args);

// Bind APNs settings from configuration
builder.Services.Configure<ApnsSettings>(
    builder.Configuration.GetSection(ApnsSettings.SectionName));

// Register APNs services
builder.Services.AddSingleton<ApnsTokenService>();
builder.Services.AddHttpClient<ApnsService>();

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();
app.MapControllers();
app.Run();
