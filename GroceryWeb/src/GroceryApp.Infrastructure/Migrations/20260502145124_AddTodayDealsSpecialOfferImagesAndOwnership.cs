using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GroceryApp.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddTodayDealsSpecialOfferImagesAndOwnership : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "CategoryId",
                table: "SpecialOffers",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ImageUrl",
                table: "SpecialOffers",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "OwnerUserId",
                table: "SpecialOffers",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "OwnerUserId",
                table: "Products",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "TodayDeals",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProductId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    OwnerUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TodayDeals", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TodayDeals_AspNetUsers_OwnerUserId",
                        column: x => x.OwnerUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_TodayDeals_Products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SpecialOffers_CategoryId",
                table: "SpecialOffers",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_SpecialOffers_OwnerUserId",
                table: "SpecialOffers",
                column: "OwnerUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Products_OwnerUserId",
                table: "Products",
                column: "OwnerUserId");

            migrationBuilder.CreateIndex(
                name: "IX_TodayDeals_IsActive_SortOrder",
                table: "TodayDeals",
                columns: new[] { "IsActive", "SortOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_TodayDeals_OwnerUserId",
                table: "TodayDeals",
                column: "OwnerUserId");

            migrationBuilder.CreateIndex(
                name: "IX_TodayDeals_ProductId",
                table: "TodayDeals",
                column: "ProductId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Products_AspNetUsers_OwnerUserId",
                table: "Products",
                column: "OwnerUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_SpecialOffers_AspNetUsers_OwnerUserId",
                table: "SpecialOffers",
                column: "OwnerUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_SpecialOffers_Categories_CategoryId",
                table: "SpecialOffers",
                column: "CategoryId",
                principalTable: "Categories",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Products_AspNetUsers_OwnerUserId",
                table: "Products");

            migrationBuilder.DropForeignKey(
                name: "FK_SpecialOffers_AspNetUsers_OwnerUserId",
                table: "SpecialOffers");

            migrationBuilder.DropForeignKey(
                name: "FK_SpecialOffers_Categories_CategoryId",
                table: "SpecialOffers");

            migrationBuilder.DropTable(
                name: "TodayDeals");

            migrationBuilder.DropIndex(
                name: "IX_SpecialOffers_CategoryId",
                table: "SpecialOffers");

            migrationBuilder.DropIndex(
                name: "IX_SpecialOffers_OwnerUserId",
                table: "SpecialOffers");

            migrationBuilder.DropIndex(
                name: "IX_Products_OwnerUserId",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "CategoryId",
                table: "SpecialOffers");

            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "SpecialOffers");

            migrationBuilder.DropColumn(
                name: "OwnerUserId",
                table: "SpecialOffers");

            migrationBuilder.DropColumn(
                name: "OwnerUserId",
                table: "Products");
        }
    }
}
