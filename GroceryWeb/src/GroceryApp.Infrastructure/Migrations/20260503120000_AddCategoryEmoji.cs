using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GroceryApp.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddCategoryEmoji : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Emoji",
                table: "Categories",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Emoji",
                table: "Categories");
        }
    }
}
