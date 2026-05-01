using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GroceryApp.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddHardwareVersionToUserDevices : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "HardwareVersion",
                table: "UserDevices",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HardwareVersion",
                table: "UserDevices");
        }
    }
}
