using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GroceryApp.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddAddressContactAndInstructions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ContactNumber",
                table: "Addresses",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DeliveryInstructions",
                table: "Addresses",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ContactNumber",
                table: "Addresses");

            migrationBuilder.DropColumn(
                name: "DeliveryInstructions",
                table: "Addresses");
        }
    }
}
