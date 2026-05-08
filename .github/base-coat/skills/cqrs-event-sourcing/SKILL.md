---
name: cqrs-event-sourcing
description: CQRS (Command Query Responsibility Segregation) and Event Sourcing patterns for scalable, auditable, distributed systems. Covers command execution, event storage, read model synchronization, eventual consistency, and event replay.
compatibility: ["backend-dev", "middleware-dev", "data-tier"]
metadata:
  category: "Architecture & Design"
  tags: ["cqrs", "event-sourcing", "event-driven", "distributed-systems", "data-persistence"]
  maturity: "production"
  audience: ["backend-developers", "architects", "platform-teams"]
allowed-tools: ["csharp", "sql", "bash", "git"]
---

# CQRS & Event Sourcing Patterns

Comprehensive patterns for implementing Command Query Responsibility Segregation (CQRS) and Event Sourcing in distributed systems.

## CQRS Overview

CQRS separates read and write logic:
- **Commands**: Operations that modify state (CreateOrder, UpdateInventory).
- **Queries**: Operations that retrieve state (GetOrder, ListOrders).
- **Events**: Records of state changes that occurred (OrderCreated, OrderShipped).

**Benefits**
- Independent scaling of read and write models
- Optimized read models for specific query patterns
- Clearer separation of concerns
- Better support for event-driven architectures
- Audit trail and temporal queries

**Trade-offs**
- Eventual consistency between write and read models
- Increased operational complexity
- Requires careful handling of consistency boundaries

## Core Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Command Side (Write)                                        │
│ ┌────────────────────────────────────────────────────────┐  │
│ │ Command Handler (e.g., CreateOrderHandler)             │  │
│ │  1. Validate command                                   │  │
│ │  2. Load aggregate from event store                    │  │
│ │  3. Apply command to aggregate                         │  │
│ │  4. Generate domain events                             │  │
│ │  5. Store events in event log                          │  │
│ │  6. Publish events to message broker                   │  │
│ └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                             ↓ Events
┌─────────────────────────────────────────────────────────────┐
│ Query Side (Read)                                           │
│ ┌────────────────────────────────────────────────────────┐  │
│ │ Event Handlers (Event Subscribers)                      │  │
│ │  1. Subscribe to events                                │  │
│ │  2. Update read models (cache, database, search index) │  │
│ │  3. Maintain eventually consistent state               │  │
│ └────────────────────────────────────────────────────────┘  │
│                                                             │
│ ┌────────────────────────────────────────────────────────┐  │
│ │ Query Handler (e.g., GetOrderHandler)                   │  │
│ │  1. Query read model                                   │  │
│ │  2. Return result (no state modification)              │  │
│ └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Commands

Commands are requests to perform actions that modify state. They are imperative and synchronous.

**Command Characteristics**
- Imperative: CreateOrder, not OrderCreated
- Synchronous: caller waits for result (success or failure)
- Stateless handlers: each handler loads state, applies business logic, produces events
- Validation: commands validate input and preconditions before producing events

**Example Command Handler (C#)**

```csharp
public class CreateOrderHandler : ICommandHandler<CreateOrderCommand>
{
    private readonly IEventStore _eventStore;
    private readonly IMessagePublisher _publisher;

    public async Task HandleAsync(CreateOrderCommand command)
    {
        // Validate command
        if (command.Items.Count == 0)
            throw new InvalidOperationException("Order must contain at least one item");

        // Load aggregate (will be empty if new aggregate)
        var order = await _eventStore.LoadAsync(command.OrderId, typeof(Order));

        // Apply command to aggregate (this may throw domain exceptions)
        order.Create(
            command.OrderId,
            command.CustomerId,
            command.Items,
            command.ShippingAddress,
            command.BillingAddress
        );

        // Get uncommitted events
        var events = order.GetUncommittedEvents();

        // Store events
        await _eventStore.AppendAsync(command.OrderId, events);

        // Publish events for read model update and external subscribers
        await _publisher.PublishAsync(events);
    }
}

// Command model
public class CreateOrderCommand
{
    public Guid OrderId { get; set; }
    public Guid CustomerId { get; set; }
    public List<OrderLineItem> Items { get; set; }
    public Address ShippingAddress { get; set; }
    public Address BillingAddress { get; set; }
}
```

## Queries

Queries retrieve state without modification. Query handlers read from optimized read models.

**Query Characteristics**
- Passive: retrieve state only
- Read from denormalized read models (optimized for specific access patterns)
- No invariant enforcement
- Can cache results aggressively

**Example Query Handler (C#)**

```csharp
public class GetOrderHandler : IQueryHandler<GetOrderQuery, OrderDetailsDto>
{
    private readonly IReadModelRepository<OrderDetailsDto> _readModelRepo;

    public async Task<OrderDetailsDto> HandleAsync(GetOrderQuery query)
    {
        var order = await _readModelRepo.GetByIdAsync(query.OrderId);
        if (order == null)
            throw new OrderNotFoundException(query.OrderId);

        return order;
    }
}

// Query model
public class GetOrderQuery
{
    public Guid OrderId { get; set; }
}

// Read model (denormalized for queries)
public class OrderDetailsDto
{
    public Guid OrderId { get; set; }
    public Guid CustomerId { get; set; }
    public DateTime CreatedAt { get; set; }
    public OrderStatus Status { get; set; }
    public decimal Total { get; set; }
    public List<OrderLineItemDto> Items { get; set; }
    public ShippingDetailsDto ShippingDetails { get; set; }
}
```

## Event Sourcing

Event Sourcing is a persistence model where all state changes are stored as immutable events. State is derived by replaying events.

### Event Store

The event store is the single source of truth. It stores events chronologically and supports replay.

**Event Store Interface**

```csharp
public interface IEventStore
{
    // Append events for an aggregate
    Task AppendAsync(Guid aggregateId, IEnumerable<DomainEvent> events);

    // Load aggregate state by replaying events
    Task<T> LoadAsync<T>(Guid aggregateId) where T : AggregateRoot;

    // Get all events for an aggregate (useful for debugging, snapshots)
    Task<IEnumerable<DomainEvent>> GetEventsAsync(Guid aggregateId);

    // Get events for all aggregates (useful for event subscriptions)
    Task<IEnumerable<(Guid AggregateId, DomainEvent Event)>> GetAllEventsAsync(long fromVersion = 0);
}
```

**Event Store Implementation Considerations**
- Ensure atomicity: either all events in a batch are stored or none.
- Maintain a global sequence number for event ordering across aggregates.
- Support snapshots for large aggregate histories to avoid replaying thousands of events.
- Implement cleanup/archival for old events (after sufficient snapshots).

### Aggregate Reconstruction from Events

```csharp
public abstract class AggregateRoot
{
    protected Guid Id { get; set; }
    private List<DomainEvent> _uncommittedEvents = new();
    protected int _version = 0; // Optimistic concurrency control

    // Apply event to state (called both during reconstruction and after handling command)
    protected abstract void Apply(DomainEvent @event);

    // Called by event store to reconstruct aggregate
    public void LoadFromHistory(IEnumerable<DomainEvent> events)
    {
        foreach (var @event in events)
        {
            Apply(@event);
            _version++;
        }
    }

    // Called by command handler to record new event
    protected void AddEvent(DomainEvent @event)
    {
        Apply(@event);
        _uncommittedEvents.Add(@event);
        _version++;
    }

    public IEnumerable<DomainEvent> GetUncommittedEvents() => _uncommittedEvents;
    public void ClearUncommittedEvents() => _uncommittedEvents.Clear();
}

// Concrete aggregate
public class Order : AggregateRoot
{
    public Guid CustomerId { get; private set; }
    public OrderStatus Status { get; private set; }
    public List<OrderLineItem> Items { get; private set; } = new();

    public void Create(Guid orderId, Guid customerId, List<OrderLineItem> items, ...)
    {
        if (items.Count == 0)
            throw new InvalidOperationException("Order must contain items");

        AddEvent(new OrderCreated(orderId, customerId, items, ...));
    }

    public void Confirm()
    {
        if (Status != OrderStatus.Pending)
            throw new InvalidOperationException("Only pending orders can be confirmed");

        AddEvent(new OrderConfirmed(Id));
    }

    protected override void Apply(DomainEvent @event)
    {
        switch (@event)
        {
            case OrderCreated e:
                Id = e.OrderId;
                CustomerId = e.CustomerId;
                Items = e.Items;
                Status = OrderStatus.Pending;
                break;

            case OrderConfirmed e:
                Status = OrderStatus.Confirmed;
                break;

            case OrderShipped e:
                Status = OrderStatus.Shipped;
                break;
        }
    }
}
```

## Read Model Synchronization

Read models are updated by event handlers. This creates eventual consistency: read models lag slightly behind the write model.

### Event Subscriber Pattern

```csharp
public interface IEventSubscriber
{
    Task OnEventAsync(DomainEvent @event);
}

// Concrete subscriber that updates read model
public class OrderDetailsReadModelUpdater : IEventSubscriber
{
    private readonly IReadModelRepository<OrderDetailsDto> _repository;

    public async Task OnEventAsync(DomainEvent @event)
    {
        switch (@event)
        {
            case OrderCreated e:
                var dto = new OrderDetailsDto
                {
                    OrderId = e.OrderId,
                    CustomerId = e.CustomerId,
                    CreatedAt = e.CreatedAt,
                    Status = OrderStatus.Pending,
                    Items = e.Items.Select(i => new OrderLineItemDto { ... }).ToList(),
                };
                await _repository.CreateAsync(dto);
                break;

            case OrderConfirmed e:
                var order = await _repository.GetByIdAsync(e.OrderId);
                order.Status = OrderStatus.Confirmed;
                await _repository.UpdateAsync(order);
                break;

            case OrderShipped e:
                var orderToShip = await _repository.GetByIdAsync(e.OrderId);
                orderToShip.Status = OrderStatus.Shipped;
                orderToShip.TrackingNumber = e.TrackingNumber;
                await _repository.UpdateAsync(orderToShip);
                break;
        }
    }
}
```

### Event Bus / Message Broker

Events are published to a message broker for asynchronous, decoupled delivery:

```csharp
public interface IMessagePublisher
{
    Task PublishAsync(IEnumerable<DomainEvent> events);
    Task SubscribeAsync<T>(IEventSubscriber subscriber) where T : DomainEvent;
}

// Usage in command handler
var events = order.GetUncommittedEvents();
await _eventStore.AppendAsync(order.Id, events);
await _messagePublisher.PublishAsync(events); // Async; subscribers notified later
```

## Eventual Consistency

Because read models update asynchronously, there is a window where they are stale relative to the write model.

**Handling Consistency Gaps**

1. **Accept staleness**: For many queries, slight lag is acceptable.
2. **Client-side caching**: Cache read results with TTL; respect cache coherency.
3. **Polling**: Client polls until consistency is achieved (polling with exponential backoff).
4. **Saga pattern**: For workflows spanning multiple aggregates, use sagas to coordinate state changes with retries.

**Example: Consistency Polling**

```csharp
public async Task WaitForConsistencyAsync(Guid orderId, Func<OrderDetailsDto, bool> condition)
{
    var maxAttempts = 10;
    var delayMs = 100;

    for (int i = 0; i < maxAttempts; i++)
    {
        var dto = await _queryHandler.HandleAsync(new GetOrderQuery { OrderId = orderId });
        if (condition(dto))
            return;

        await Task.Delay(delayMs);
        delayMs = Math.Min(delayMs * 2, 5000); // Exponential backoff, max 5s
    }

    throw new ConsistencyTimeoutException("Read model did not reach expected state");
}
```

## Snapshots

For large aggregates with long event histories, replaying all events is slow. Snapshots capture aggregate state at points in time.

**Snapshot Strategy**
- Create a snapshot every N events (e.g., every 100 events) or after each command handler completes.
- When loading, fetch the latest snapshot, then replay events since the snapshot.
- Store snapshots separately from events to avoid slowing down the event stream.

```csharp
public interface ISnapshotStore
{
    Task SaveSnapshotAsync(Guid aggregateId, AggregateSnapshot snapshot);
    Task<AggregateSnapshot> GetLatestSnapshotAsync(Guid aggregateId);
}

// Event store loading with snapshot support
public async Task<T> LoadWithSnapshotAsync<T>(Guid aggregateId) where T : AggregateRoot
{
    var snapshot = await _snapshotStore.GetLatestSnapshotAsync(aggregateId);
    var aggregate = snapshot != null
        ? (T)Activator.CreateInstance(typeof(T), snapshot.State)
        : (T)Activator.CreateInstance(typeof(T));

    var events = await _eventStore.GetEventsAfterAsync(aggregateId, snapshot?.Version ?? 0);
    aggregate.LoadFromHistory(events);
    return aggregate;
}
```

## Event Versioning

Events evolve as business requirements change. Versioning ensures backward compatibility.

**Event Version Strategy**
- Each event includes a `version` field (default: 1).
- New versions are treated as new event types (OrderCreatedV2, not OrderCreated v2).
- Subscribers must handle all versions.
- Prefer upcasting (converting old versions to new versions during deserialization) over duplicating handler logic.

```csharp
public interface IEventUpcaster
{
    DomainEvent Upcast(object oldEventData);
}

// Upcast OrderCreatedV1 to OrderCreatedV2
public class OrderCreatedUpcaster : IEventUpcaster
{
    public DomainEvent Upcast(object oldEventData)
    {
        var v1 = (OrderCreatedV1)oldEventData;
        return new OrderCreated(v1.OrderId, v1.CustomerId, v1.Items, 
            new Money(v1.Total, "USD")); // Add currency if it was implicit
    }
}
```

## Saga Pattern for Distributed Transactions

Sagas coordinate multi-aggregate workflows using events and compensating actions.

**Saga Characteristics**
- Consists of steps (each step is a command or event handler).
- Each step publishes events that trigger the next step.
- Compensating actions undo previous steps on failure.
- No distributed transactions; eventual consistency.

**Example: Order Fulfillment Saga**

```
1. OrderCreated event fires
2. InventoryService consumes OrderCreated → AllocateInventory command → InventoryAllocated event
3. ShippingService consumes InventoryAllocated → CreateShipment command → ShipmentCreated event
4. If inventory allocation fails → Saga compensates: OrderCreationFailed event
```

## Operational Concerns

### Event Replay

Replaying events from the beginning to verify aggregate state or fix corrupted read models.

```csharp
public async Task RebuildReadModelAsync(Type readModelType)
{
    // Clear read model
    await _readModelRepository.ClearAsync(readModelType);

    // Get all events from the beginning
    var allEvents = await _eventStore.GetAllEventsAsync(0);

    // Reprocess each event through subscribers
    foreach (var (aggregateId, @event) in allEvents)
    {
        await _readModelUpdater.OnEventAsync(@event);
    }

    Console.WriteLine("Read model rebuild complete");
}
```

### Monitoring and Observability

- Track event publishing latency and subscriber processing latency.
- Monitor dead letter queues for failed event deliveries.
- Alert on read model lag (difference between max event timestamp and read model last update).
- Include `correlationId` and `traceId` in events for distributed tracing.

### Disaster Recovery

- Archive old event data for long-term retention (compliance, auditing).
- Maintain backups of event store and snapshots.
- Test event replay and snapshot recovery procedures regularly.

## Best Practices

1. **Keep aggregates small**: Smaller aggregates = faster event replay.
2. **Immutable events**: Events never change; only new events are appended.
3. **Versioning from day one**: Version events and read models from the start; retrofitting is expensive.
4. **Test event handlers**: Unit test each event handler in isolation.
5. **Monitor eventual consistency**: Alert if read models fall too far behind.
6. **Use snapshots carefully**: Snapshot too frequently = slower event store; too infrequently = slow replay.
7. **Document event contracts**: Every event should have a clear schema and versioning strategy.
8. **Idempotent subscribers**: Subscribers must handle duplicate event deliveries.

## Standards and References

- **Microsoft CQRS Documentation** — Patterns and guidance for implementing CQRS.
- **Event Sourcing by Martin Fowler** — Foundational article on event sourcing concepts.
- **Implementing CQRS by Vaughn Vernon** — Pragmatic CQRS patterns in C#.
- **Domain Events by Udi Dahan** — Event-driven architecture and domain events.
- **Saga Pattern by Chris Richardson** — Managing distributed transactions with sagas.
- **EventStoreDB Documentation** — Reference event sourcing implementation and patterns.
