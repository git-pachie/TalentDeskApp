using GroceryApp.Admin.Models;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace GroceryApp.Admin.Services;

public class OrderPdfDocument : IDocument
{
    private readonly OrderModel _order;

    public OrderPdfDocument(OrderModel order)
    {
        _order = order;
    }

    public DocumentMetadata GetMetadata() => DocumentMetadata.Default;

    public void Compose(IDocumentContainer container)
    {
        container.Page(page =>
        {
            page.Size(PageSizes.A4);
            page.Margin(36);
            page.DefaultTextStyle(x => x.FontSize(10).FontFamily("Arial"));

            page.Header().Element(ComposeHeader);
            page.Content().Element(ComposeContent);
            page.Footer().AlignCenter().Text(x =>
            {
                x.Span("Page ");
                x.CurrentPageNumber();
                x.Span(" of ");
                x.TotalPages();
                x.Span($"  ·  Generated {DateTime.Now:MMM dd, yyyy HH:mm}").FontSize(8).FontColor(Colors.Grey.Medium);
            });
        });
    }

    private void ComposeHeader(IContainer container)
    {
        container.Column(col =>
        {
            col.Item().Row(row =>
            {
                row.RelativeItem().Column(c =>
                {
                    c.Item().Text("GroceryApp").FontSize(20).Bold().FontColor(Colors.Green.Darken2);
                    c.Item().Text("Order Invoice").FontSize(12).FontColor(Colors.Grey.Darken1);
                });
                row.ConstantItem(160).Column(c =>
                {
                    c.Item().AlignRight().Text(_order.OrderNumber).FontSize(14).Bold();
                    c.Item().AlignRight().Text(_order.CreatedAt.ToString("MMMM dd, yyyy")).FontSize(9).FontColor(Colors.Grey.Medium);
                    if (_order.DeliveryDate.HasValue)
                        c.Item().AlignRight().Text($"Delivery: {_order.DeliveryDate.Value:MMM dd, yyyy}{(string.IsNullOrWhiteSpace(_order.DeliveryTimeSlot) ? " (Anytime)" : $" · {_order.DeliveryTimeSlot}")}")
                            .FontSize(8).FontColor(Colors.Grey.Darken1);
                    c.Item().AlignRight().Text($"Status: {_order.Status}").FontSize(9)
                        .FontColor(_order.Status == "Delivered" ? Colors.Green.Darken2 :
                                   _order.Status == "Cancelled" ? Colors.Red.Medium :
                                   Colors.Orange.Medium);
                });
            });

            col.Item().PaddingTop(6).LineHorizontal(1).LineColor(Colors.Green.Lighten2);
        });
    }

    private void ComposeContent(IContainer container)
    {
        container.PaddingTop(12).Column(col =>
        {
            // Customer + Address row
            col.Item().Row(row =>
            {
                // Customer
                row.RelativeItem().Border(1).BorderColor(Colors.Grey.Lighten2).Padding(10).Column(c =>
                {
                    c.Item().Text("Customer").FontSize(9).Bold().FontColor(Colors.Grey.Darken1);
                    c.Item().PaddingTop(4).Text(_order.CustomerName).Bold();
                    if (!string.IsNullOrEmpty(_order.CustomerEmail))
                        c.Item().Text(_order.CustomerEmail).FontSize(9).FontColor(Colors.Grey.Darken1);
                    if (!string.IsNullOrEmpty(_order.CustomerPhone))
                        c.Item().Text(_order.CustomerPhone).FontSize(9).FontColor(Colors.Grey.Darken1);
                });

                row.ConstantItem(12);

                // Delivery Address
                row.RelativeItem().Border(1).BorderColor(Colors.Grey.Lighten2).Padding(10).Column(c =>
                {
                    c.Item().Text("Delivery Address").FontSize(9).Bold().FontColor(Colors.Grey.Darken1);
                    if (_order.Address is not null)
                    {
                        c.Item().PaddingTop(4).Text($"{_order.Address.Label}").Bold();
                        c.Item().Text(_order.Address.Street).FontSize(9);
                        c.Item().Text($"{_order.Address.City}, {_order.Address.Province} {_order.Address.ZipCode}").FontSize(9);
                        if (!string.IsNullOrEmpty(_order.Address.ContactNumber))
                            c.Item().Text($"Contact: {_order.Address.ContactNumber}").FontSize(9).FontColor(Colors.Grey.Darken1);
                        if (!string.IsNullOrEmpty(_order.Address.DeliveryInstructions))
                            c.Item().Text($"Notes: {_order.Address.DeliveryInstructions}").FontSize(9).FontColor(Colors.Grey.Darken1);
                    }
                    else
                    {
                        c.Item().PaddingTop(4).Text("No address provided").FontSize(9).FontColor(Colors.Grey.Medium);
                    }
                });

                row.ConstantItem(12);

                row.RelativeItem().Border(1).BorderColor(Colors.Grey.Lighten2).Padding(10).Column(c =>
                {
                    c.Item().Text("Delivery Schedule").FontSize(9).Bold().FontColor(Colors.Grey.Darken1);
                    if (_order.DeliveryDate.HasValue)
                    {
                        c.Item().PaddingTop(4).Text(_order.DeliveryDate.Value.ToString("MMMM dd, yyyy")).Bold();
                        c.Item().Text(string.IsNullOrWhiteSpace(_order.DeliveryTimeSlot) ? "Anytime" : _order.DeliveryTimeSlot).FontSize(9).FontColor(Colors.Grey.Darken1);
                    }
                    else
                    {
                        c.Item().PaddingTop(4).Text("Not specified").FontSize(9).FontColor(Colors.Grey.Medium);
                    }
                });

                row.ConstantItem(12);

                // Payment
                row.RelativeItem().Border(1).BorderColor(Colors.Grey.Lighten2).Padding(10).Column(c =>
                {
                    c.Item().Text("Payment").FontSize(9).Bold().FontColor(Colors.Grey.Darken1);
                    if (_order.Payment is not null)
                    {
                        c.Item().PaddingTop(4).Text(_order.Payment.Method).Bold();
                        c.Item().Text($"Status: {_order.Payment.Status}").FontSize(9);
                        if (_order.Payment.PaidAt.HasValue)
                            c.Item().Text($"Paid: {_order.Payment.PaidAt.Value:MMM dd, yyyy HH:mm}").FontSize(9).FontColor(Colors.Grey.Darken1);
                    }
                    else
                    {
                        c.Item().PaddingTop(4).Text("Pending").FontSize(9).FontColor(Colors.Grey.Medium);
                    }
                });
            });

            col.Item().PaddingTop(16).Text("Order Items").FontSize(11).Bold();
            col.Item().PaddingTop(6).Table(table =>
            {
                table.ColumnsDefinition(cols =>
                {
                    cols.RelativeColumn(4);
                    cols.RelativeColumn(2);
                    cols.RelativeColumn(1);
                    cols.RelativeColumn(2);
                });

                // Header
                table.Header(header =>
                {
                    void HeaderCell(string text) =>
                        header.Cell().Background(Colors.Green.Lighten4).Padding(6)
                              .Text(text).Bold().FontSize(9);

                    HeaderCell("Product");
                    HeaderCell("Unit Price");
                    HeaderCell("Qty");
                    HeaderCell("Total");
                });

                // Rows
                foreach (var item in _order.Items)
                {
                    table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Column(c =>
                    {
                        c.Item().Text(item.ProductName).Bold().FontSize(9);
                        if (!string.IsNullOrEmpty(item.Remarks))
                            c.Item().Text($"Note: {item.Remarks}").FontSize(8).FontColor(Colors.Grey.Medium);
                    });
                    table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6)
                         .AlignRight().Text($"₱{item.UnitPrice:N2}").FontSize(9);
                    table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6)
                         .AlignCenter().Text(item.Quantity.ToString()).FontSize(9);
                    table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6)
                         .AlignRight().Text($"₱{item.TotalPrice:N2}").Bold().FontSize(9);
                }
            });

            // Totals
            col.Item().PaddingTop(8).AlignRight().Width(220).Column(c =>
            {
                void TotalRow(string label, string value, bool bold = false, string? color = null)
                {
                    c.Item().Row(r =>
                    {
                        var labelText = r.RelativeItem().Text(label).FontSize(9);
                        if (color is not null) labelText.FontColor(color);
                        var valueText = r.ConstantItem(90).AlignRight().Text(value).FontSize(9);
                        if (bold) valueText.Bold();
                        if (color is not null) valueText.FontColor(color);
                    });
                    c.Item().PaddingBottom(2);
                }

                TotalRow("Subtotal", $"₱{_order.SubTotal:N2}");
                if (_order.DiscountAmount > 0)
                    TotalRow("Discount", $"-₱{_order.DiscountAmount:N2}", color: Colors.Green.Darken2);
                TotalRow("Delivery Fee", $"₱{_order.DeliveryFee:N2}");
                TotalRow("Platform Fee", $"₱{_order.PlatformFee:N2}");
                TotalRow("Other Charges", $"₱{_order.OtherCharges:N2}");
                c.Item().LineHorizontal(1).LineColor(Colors.Grey.Lighten2);
                c.Item().PaddingTop(4);
                TotalRow("TOTAL", $"₱{_order.TotalAmount:N2}", bold: true);
            });

            // Remarks
            if (!string.IsNullOrEmpty(_order.Notes))
            {
                col.Item().PaddingTop(12).Border(1).BorderColor(Colors.Grey.Lighten2).Padding(10).Column(c =>
                {
                    c.Item().Text("Order Remarks").FontSize(9).Bold().FontColor(Colors.Grey.Darken1);
                    c.Item().PaddingTop(4).Text(_order.Notes).FontSize(9);
                });
            }
        });
    }
}
