using GroceryApp.Application.DTOs.Payments;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class PaymentService : IPaymentService
{
    private readonly IRepository<Payment> _paymentRepo;
    private readonly IRepository<Order> _orderRepo;
    private readonly IEnumerable<IPaymentProvider> _providers;
    private readonly INotificationService _notificationService;
    private readonly IUnitOfWork _unitOfWork;

    public PaymentService(
        IRepository<Payment> paymentRepo,
        IRepository<Order> orderRepo,
        IEnumerable<IPaymentProvider> providers,
        INotificationService notificationService,
        IUnitOfWork unitOfWork)
    {
        _paymentRepo = paymentRepo;
        _orderRepo = orderRepo;
        _providers = providers;
        _notificationService = notificationService;
        _unitOfWork = unitOfWork;
    }

    public async Task<PaymentResultDto> ProcessCheckoutAsync(Guid userId, CheckoutRequest request)
    {
        var order = await _orderRepo.FirstOrDefaultAsync(o => o.Id == request.OrderId && o.UserId == userId);
        if (order is null)
            throw new InvalidOperationException("Order not found.");

        if (order.Status != OrderStatus.Pending)
            throw new InvalidOperationException("Order is not in a payable state.");

        // Apple Pay routes through Stripe
        var effectiveMethod = request.Method == PaymentMethod.ApplePay ? PaymentMethod.Card : request.Method;
        var provider = _providers.FirstOrDefault(p => p.SupportedMethod == effectiveMethod)
            ?? throw new InvalidOperationException($"Payment method {request.Method} is not supported.");

        var payment = new Payment
        {
            OrderId = order.Id,
            UserId = userId,
            Amount = order.TotalAmount,
            Method = request.Method,
            Status = PaymentStatus.Pending
        };

        await _paymentRepo.AddAsync(payment);
        await _unitOfWork.SaveChangesAsync();

        var result = await provider.ProcessPaymentAsync(payment, request);

        if (result.Success)
        {
            payment.Status = PaymentStatus.Paid;
            payment.ExternalTransactionId = result.ExternalTransactionId;
            payment.PaidAt = DateTime.UtcNow;
            order.Status = OrderStatus.Paid;
            order.UpdatedAt = DateTime.UtcNow;
        }
        else if (!string.IsNullOrEmpty(result.RedirectUrl))
        {
            // Pending — waiting for webhook (GCash/PayMaya)
            payment.ProviderReference = result.ExternalTransactionId;
        }
        else
        {
            payment.Status = PaymentStatus.Failed;
            payment.FailureReason = result.FailureReason;
        }

        _paymentRepo.Update(payment);
        _orderRepo.Update(order);
        await _unitOfWork.SaveChangesAsync();

        if (result.Success)
        {
            await _notificationService.CreateNotificationAsync(
                userId, "Payment Successful", $"Payment for order {order.OrderNumber} confirmed.", "payment", order.Id.ToString());
        }

        return new PaymentResultDto
        {
            Success = result.Success,
            PaymentId = payment.Id,
            Status = payment.Status.ToString(),
            RedirectUrl = result.RedirectUrl,
            FailureReason = result.FailureReason
        };
    }

    public async Task HandleWebhookAsync(string providerName, string payload, string? signature)
    {
        var provider = _providers.FirstOrDefault(p =>
            p.SupportedMethod.ToString().Equals(providerName, StringComparison.OrdinalIgnoreCase))
            ?? throw new InvalidOperationException($"Unknown provider: {providerName}");

        var isValid = await provider.ValidateWebhookAsync(payload, signature);
        if (!isValid)
            throw new InvalidOperationException("Invalid webhook signature.");

        var webhookResult = await provider.HandleWebhookAsync(payload);
        if (webhookResult.ExternalTransactionId is null) return;

        var payment = await _paymentRepo.Query()
            .Include(p => p.Order)
            .FirstOrDefaultAsync(p => p.ProviderReference == webhookResult.ExternalTransactionId
                || p.ExternalTransactionId == webhookResult.ExternalTransactionId);

        if (payment is null) return;

        payment.Status = webhookResult.NewStatus;
        if (webhookResult.NewStatus == PaymentStatus.Paid)
        {
            payment.PaidAt = DateTime.UtcNow;
            payment.Order.Status = OrderStatus.Paid;
            payment.Order.UpdatedAt = DateTime.UtcNow;

            await _notificationService.CreateNotificationAsync(
                payment.UserId, "Payment Successful", $"Payment for order {payment.Order.OrderNumber} confirmed.", "payment", payment.OrderId.ToString());
        }
        else if (webhookResult.NewStatus == PaymentStatus.Failed)
        {
            payment.FailureReason = "Payment declined by provider.";
        }

        _paymentRepo.Update(payment);
        _orderRepo.Update(payment.Order);
        await _unitOfWork.SaveChangesAsync();
    }
}
