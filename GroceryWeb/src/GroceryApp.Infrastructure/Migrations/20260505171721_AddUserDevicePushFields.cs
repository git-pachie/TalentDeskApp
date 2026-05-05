using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GroceryApp.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddUserDevicePushFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Platform",
                table: "UserDevices",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PushToken",
                table: "UserDevices",
                type: "nvarchar(512)",
                maxLength: 512,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Platform",
                table: "UserDevices");

            migrationBuilder.DropColumn(
                name: "PushToken",
                table: "UserDevices");
        }
    }
}
