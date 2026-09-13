#!/bin/bash
# =============================================================================
#  Full-Stack CRUD Generator (Clean Architecture)
#  .NET 10 Web API  +  Angular 22 (zoneless)  +  Tailwind CSS v4
#
#  Generates:
#    - Clean Architecture solution (Domain / Application / Infrastructure / Api)
#    - JWT Authentication + Swagger UI (Swashbuckle) + /health endpoint
#    - EF Core migrations + auto-migration & admin seeding on startup
#    - Angular standalone app with Tailwind v4 (.postcssrc.json included)
#
#  Generated app URLs:
#    API      : http://localhost:5001
#    Swagger  : http://localhost:5001/swagger
#    Frontend : http://localhost:4200
#    Admin    : admin / Admin@12345
# =============================================================================

set -u

echo "=================================================="
echo " Full-Stack CRUD Generator (Clean Architecture)   "
echo " .NET 10 + Angular + Tailwind v4 + Swagger UI     "
echo "=================================================="

# ---------- helpers ----------
fail() { echo ""; echo "❌ ERROR: $1"; echo "   Fix the problem and re-run this script."; exit 1; }
warn() { echo "⚠️  $1"; }

# Escape a string so it can be used safely as a sed replacement (| delimiter).
escape_repl() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }

# ---------- prerequisites ----------
command -v dotnet >/dev/null 2>&1 || fail ".NET SDK is not installed."
command -v node   >/dev/null 2>&1 || fail "Node.js is not installed."
command -v npm    >/dev/null 2>&1 || fail "npm is not installed."

# ---------- project name ----------
read -p "Enter project name (e.g., NewApp): " PROJECT_NAME
[ -z "$PROJECT_NAME" ] && fail "Project name cannot be empty."
if [ -d "$PROJECT_NAME" ]; then
    fail "Directory '$PROJECT_NAME' already exists. Delete it (or choose another name) first."
fi

PROJECT_NAME_LOWER=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')
UI_NAME="${PROJECT_NAME_LOWER}-ui"
API_PORT=5001
ADMIN_USER="admin"
ADMIN_PASSWORD="Admin@12345"

# ==========================================
# 🔹 INTERACTIVE DATABASE CONFIGURATION 🔹
# ==========================================
echo ""
echo "🗄️  Database Configuration:"
echo "-------------------------------------------"
read -p "Database Type (1=PostgreSQL [default], 2=SQL Server) [1]: " DB_CHOICE
DB_CHOICE=${DB_CHOICE:-1}

if [ "$DB_CHOICE" = "2" ]; then
    DB_TYPE="SqlServer"
    DEFAULT_HOST="localhost"
    DEFAULT_PORT="1433"
    DEFAULT_USER="sa"
    PKG_PROVIDER="Microsoft.EntityFrameworkCore.SqlServer"
else
    DB_TYPE="PostgreSQL"
    DEFAULT_HOST="localhost"
    DEFAULT_PORT="5432"
    DEFAULT_USER="postgres"
    PKG_PROVIDER="Npgsql.EntityFrameworkCore.PostgreSQL"
fi

read -p "Host [$DEFAULT_HOST]: " DB_HOST
DB_HOST=${DB_HOST:-$DEFAULT_HOST}
read -p "Port [$DEFAULT_PORT]: " DB_PORT
DB_PORT=${DB_PORT:-$DEFAULT_PORT}
read -p "Database Name [$PROJECT_NAME_LOWER]: " DB_NAME
DB_NAME=${DB_NAME:-$PROJECT_NAME_LOWER}
read -p "Username [$DEFAULT_USER]: " DB_USER
DB_USER=${DB_USER:-$DEFAULT_USER}
read -s -p "Password: " DB_PASSWORD
echo ""

# Build Connection String (single-quote values containing special characters)
if [ "$DB_TYPE" = "PostgreSQL" ]; then
    if [[ "$DB_PASSWORD" == *[\'\;\ ]* ]]; then
        ESCAPED_PW="'${DB_PASSWORD//\'/\'\'}'"
    else
        ESCAPED_PW="$DB_PASSWORD"
    fi
    CONN_STR="Host=$DB_HOST;Port=$DB_PORT;Database=$DB_NAME;Username=$DB_USER;Password=$ESCAPED_PW"
    USE_DB_CODE='options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"))'
else
    CONN_STR="Server=$DB_HOST,$DB_PORT;Database=$DB_NAME;User Id=$DB_USER;Password=$DB_PASSWORD;TrustServerCertificate=True"
    USE_DB_CODE='options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"))'
fi

# Random JWT signing key per project (>= 64 chars)
if command -v openssl >/dev/null 2>&1; then
    JWT_KEY=$(openssl rand -base64 48 2>/dev/null | tr -d '\r\n')
fi
[ -z "${JWT_KEY:-}" ] && JWT_KEY=$(head -c 48 /dev/urandom 2>/dev/null | base64 | tr -d '\r\n')
[ -z "$JWT_KEY" ] && JWT_KEY="FALLBACK_SECRET_KEY_PLEASE_CHANGE_0123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# Test Connectivity (port check using /dev/tcp - works on bash & Git Bash)
echo ""
echo "🔍 Testing connectivity to $DB_HOST:$DB_PORT ..."
if (echo > "/dev/tcp/$DB_HOST/$DB_PORT") >/dev/null 2>&1; then
    echo "✅ Port is reachable. Proceeding..."
else
    warn "Cannot reach $DB_HOST on port $DB_PORT."
    echo "   (Migrations will still be generated; the API applies them on startup.)"
    read -p "   Continue anyway? (y/n) [y]: " CONT
    CONT=${CONT:-y}
    [ "$CONT" != "y" ] && { echo "Aborted."; exit 1; }
fi
echo "-------------------------------------------"

# Placeholder substitution for every generated file
substitute() {
    sed -i \
        -e "s|__PROJECT_NAME__|$(escape_repl "$PROJECT_NAME")|g" \
        -e "s|__PROJECT_NAME_LOWER__|$(escape_repl "$PROJECT_NAME_LOWER")|g" \
        -e "s|__CONN_STR__|$(escape_repl "$CONN_STR")|g" \
        -e "s|__USE_DB__|$(escape_repl "$USE_DB_CODE")|g" \
        -e "s|__JWT_KEY__|$(escape_repl "$JWT_KEY")|g" \
        -e "s|__API_PORT__|$(escape_repl "$API_PORT")|g" \
        -e "s|__ADMIN_PASSWORD__|$(escape_repl "$ADMIN_PASSWORD")|g" \
        "$1"
}

echo "🚀 Creating project structure for $PROJECT_NAME..."
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME" || fail "Cannot create directory '$PROJECT_NAME'."

# ==========================================
# 1. BACKEND: .NET SOLUTION & PROJECTS
# ==========================================
echo "📦 Creating .NET Solution and Projects..."
dotnet new sln -n "$PROJECT_NAME"                 >/dev/null || fail "dotnet new sln failed."
dotnet new classlib -n "$PROJECT_NAME.Domain"         >/dev/null || fail "dotnet new classlib (Domain) failed."
dotnet new classlib -n "$PROJECT_NAME.Application"    >/dev/null || fail "dotnet new classlib (Application) failed."
dotnet new classlib -n "$PROJECT_NAME.Infrastructure" >/dev/null || fail "dotnet new classlib (Infrastructure) failed."
dotnet new webapi -n "$PROJECT_NAME.Api" --use-controllers >/dev/null || fail "dotnet new webapi failed."

dotnet sln add "$PROJECT_NAME.Domain/$PROJECT_NAME.Domain.csproj"             >/dev/null
dotnet sln add "$PROJECT_NAME.Application/$PROJECT_NAME.Application.csproj"   >/dev/null
dotnet sln add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" >/dev/null
dotnet sln add "$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj"                   >/dev/null

echo "🔗 Linking Clean Architecture Dependencies..."
dotnet add "$PROJECT_NAME.Application/$PROJECT_NAME.Application.csproj" reference "$PROJECT_NAME.Domain/$PROJECT_NAME.Domain.csproj"         >/dev/null
dotnet add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" reference "$PROJECT_NAME.Application/$PROJECT_NAME.Application.csproj" >/dev/null
dotnet add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" reference "$PROJECT_NAME.Domain/$PROJECT_NAME.Domain.csproj"           >/dev/null
dotnet add "$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj" reference "$PROJECT_NAME.Application/$PROJECT_NAME.Application.csproj"       >/dev/null
dotnet add "$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj" reference "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" >/dev/null

echo "📦 Installing NuGet Packages..."
echo " -> EF Core + Provider ($PKG_PROVIDER)..."
dotnet add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" package Microsoft.EntityFrameworkCore            >/dev/null || fail "EF Core package install failed."
dotnet add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" package "$PKG_PROVIDER"                          >/dev/null || fail "DB provider package install failed."
echo " -> EF Core Design (Infrastructure + Api, required by dotnet-ef)..."
dotnet add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" package Microsoft.EntityFrameworkCore.Design     >/dev/null || fail "EF Design (Infrastructure) install failed."
dotnet add "$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj" package Microsoft.EntityFrameworkCore.Design                           >/dev/null || fail "EF Design (Api) install failed."
echo " -> JWT Bearer..."
dotnet add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" package Microsoft.AspNetCore.Authentication.JwtBearer >/dev/null || fail "JwtBearer (Infrastructure) install failed."
dotnet add "$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj" package Microsoft.AspNetCore.Authentication.JwtBearer                       >/dev/null || fail "JwtBearer (Api) install failed."
echo " -> Swashbuckle (Swagger UI)..."
dotnet add "$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj" package Swashbuckle.AspNetCore                                             >/dev/null || fail "Swashbuckle install failed."

# Remove template noise
rm -f "$PROJECT_NAME.Domain/Class1.cs" "$PROJECT_NAME.Application/Class1.cs" "$PROJECT_NAME.Infrastructure/Class1.cs"
rm -f "$PROJECT_NAME.Api/WeatherForecast.cs" "$PROJECT_NAME.Api/Controllers/WeatherForecastController.cs"
rm -f "$PROJECT_NAME.Api/$PROJECT_NAME.Api.http"

mkdir -p "$PROJECT_NAME.Domain/Entities" "$PROJECT_NAME.Domain/Enums" "$PROJECT_NAME.Domain/Events" "$PROJECT_NAME.Domain/Exceptions" "$PROJECT_NAME.Domain/ValueObjects"
mkdir -p "$PROJECT_NAME.Application/DTOs" "$PROJECT_NAME.Application/Interfaces" "$PROJECT_NAME.Application/Services" "$PROJECT_NAME.Application/Validation" "$PROJECT_NAME.Application/Mappings" "$PROJECT_NAME.Application/Behaviors"
mkdir -p "$PROJECT_NAME.Infrastructure/Persistence/Configurations" "$PROJECT_NAME.Infrastructure/Repositories" "$PROJECT_NAME.Infrastructure/Security" "$PROJECT_NAME.Infrastructure/Services"
mkdir -p "$PROJECT_NAME.Api/Controllers" "$PROJECT_NAME.Api/Middleware" "$PROJECT_NAME.Api/Filters" "$PROJECT_NAME.Api/Extensions" "$PROJECT_NAME.Api/Properties"

# --- LAYER FOLDER DOCS (README.md in every architectural folder) ---

# Domain layer
cat <<'EOF' > "$PROJECT_NAME.Domain/Entities/README.md"
# Domain — Entities

Business entities of the application. They represent the core data and
identity of the system and must have **no dependencies** on any other layer
(pure C#, no EF Core, no ASP.NET attributes).

```csharp
namespace __PROJECT_NAME__.Domain.Entities;

public class Product
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public decimal Price { get; set; }
    public bool IsActive { get; set; } = true;
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Domain/Enums/README.md"
# Domain — Enums

Enumerations shared across the whole solution. Prefer enums over magic
strings for values that come from a fixed set (statuses, types, ...).

```csharp
namespace __PROJECT_NAME__.Domain.Enums;

public enum OrderStatus
{
    Pending = 1,
    Paid = 2,
    Shipped = 3,
    Cancelled = 4
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Domain/Events/README.md"
# Domain — Events

Domain events describe something meaningful that happened in the business
(e.g. "a user was registered"). A publisher (in-process dispatcher, MediatR,
or a message broker) can raise them and handlers can react.

```csharp
namespace __PROJECT_NAME__.Domain.Events;

public record UserRegisteredEvent(Guid UserId, string Email, DateTime OccurredAtUtc);
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Domain/Exceptions/README.md"
# Domain — Exceptions

Custom exceptions raised by domain rules and use cases. Map them to HTTP
status codes in the API layer (e.g. with an exception-handling middleware).

```csharp
namespace __PROJECT_NAME__.Domain.Exceptions;

public class NotFoundException(string entity, object key)
    : Exception($"{entity} with key '{key}' was not found.");

public class ConflictException(string message) : Exception(message);
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Domain/ValueObjects/README.md"
# Domain — ValueObjects

Value objects are immutable types defined by their attributes (money, email,
address). They enforce their own invariants on creation and have no identity.

```csharp
namespace __PROJECT_NAME__.Domain.ValueObjects;

public record Email
{
    public string Value { get; }

    private Email(string value) => Value = value;

    public static Email Create(string value)
    {
        if (string.IsNullOrWhiteSpace(value) || !value.Contains('@'))
            throw new ArgumentException("Invalid email address.");
        return new Email(value.Trim().ToLowerInvariant());
    }

    public override string ToString() => Value;
}
```
EOF

# Application layer
cat <<'EOF' > "$PROJECT_NAME.Application/DTOs/README.md"
# Application — DTOs

Data Transfer Objects cross the layer boundary between the API and the
application services. DTOs are plain records/classes shaped for each use
case (request/response) and never leak EF entities outside the layer.

```csharp
namespace __PROJECT_NAME__.Application.DTOs;

public record ProductDto(Guid Id, string Name, decimal Price, bool IsActive);
public record CreateProductRequest(string Name, decimal Price);
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Application/Interfaces/README.md"
# Application — Interfaces

Abstractions the application layer depends on. Services here define *what*
is needed (persistence, security, external APIs) while the Infrastructure
layer provides *how* it is done. This keeps the dependency rule intact.

```csharp
namespace __PROJECT_NAME__.Application.Interfaces;

public interface IProductRepository
{
    Task<List<Product>> GetAllAsync(CancellationToken ct = default);
    Task AddAsync(Product product, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Application/Services/README.md"
# Application — Services

Application services orchestrate use cases: they validate input, apply
business rules, call repositories and map entities to DTOs. They are
registered in DI and consumed by controllers.

```csharp
public async Task<ProductDto> CreateAsync(CreateProductRequest request, CancellationToken ct)
{
    var product = new Product { Id = Guid.NewGuid(), Name = request.Name, Price = request.Price };
    await repo.AddAsync(product, ct);
    await repo.SaveChangesAsync(ct);
    return new ProductDto(product.Id, product.Name, product.Price, product.IsActive);
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Application/Validation/README.md"
# Application — Validation

Input validators for requests (FluentValidation style). Each validator
checks one request type and returns a list of errors that the API can turn
into a 400 Bad Request response.

```csharp
public class CreateProductRequestValidator
{
    public List<string> Validate(CreateProductRequest request)
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(request.Name))
            errors.Add("Name is required.");
        if (request.Price < 0)
            errors.Add("Price must be greater than or equal to zero.");
        return errors;
    }
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Application/Mappings/README.md"
# Application — Mappings

Object-to-object mapping configuration between entities and DTOs
(e.g. AutoMapper profiles or static mapper classes). Keeping maps in one
place avoids scattered copy-paste conversion code.

```csharp
public static class UserMapper
{
    public static UserDto ToDto(this AppUser user) =>
        new(user.Id, user.UserName, user.Email, user.Role, user.IsActive);
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Application/Behaviors/README.md"
# Application — Behaviors

Cross-cutting pipeline behaviors (MediatR `IPipelineBehavior` style):
logging, performance timing, validation or transaction handling wrapped
around every use case without touching its code.

```csharp
public class LoggingBehavior<TRequest, TResponse>(ILogger<TRequest> logger)
    : IPipelineBehavior<TRequest, TResponse> where TRequest : notnull
{
    public async Task<TResponse> Handle(TRequest request, Func<Task<TResponse>> next, CancellationToken ct)
    {
        logger.LogInformation("Handling {RequestType}", typeof(TRequest).Name);
        var response = await next();
        logger.LogInformation("Handled {RequestType}", typeof(TRequest).Name);
        return response;
    }
}
```
EOF

# Infrastructure layer
cat <<'EOF' > "$PROJECT_NAME.Infrastructure/Persistence/README.md"
# Infrastructure — Persistence

Everything that talks to the database: the EF Core `DbContext`, the
migration initializer and seeding logic (`DbInitializer`), plus the
`Migrations/` folder generated by `dotnet ef`.

```csharp
public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<AppUser> Users => Set<AppUser>();
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Infrastructure/Persistence/Configurations/README.md"
# Infrastructure — Persistence/Configurations

Fluent API entity configurations (`IEntityTypeConfiguration<T>`). Keep table
mapping rules (keys, lengths, indexes, relations) here instead of bloating
`OnModelCreating` — each entity gets its own configuration class.

```csharp
public class AppUserConfiguration : IEntityTypeConfiguration<AppUser>
{
    public void Configure(EntityTypeBuilder<AppUser> builder)
    {
        builder.Property(x => x.UserName).HasMaxLength(100).IsRequired();
        builder.HasIndex(x => x.UserName).IsUnique();
    }
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Infrastructure/Repositories/README.md"
# Infrastructure — Repositories

Implementations of the repository interfaces declared in
`Application/Interfaces`. Repositories encapsulate EF Core queries so the
application layer never sees the ORM directly.

```csharp
public class UserRepository(AppDbContext db) : IUserRepository
{
    public Task<List<AppUser>> GetAllAsync(CancellationToken ct = default) =>
        db.Users.AsNoTracking().OrderBy(x => x.UserName).ToListAsync(ct);
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Infrastructure/Security/README.md"
# Infrastructure — Security

Security-related implementations: password hashing (PBKDF2), JWT token
creation and anything else crypto/auth related. Interfaces live in
`Application/Interfaces`, implementations live here.

```csharp
public string Hash(string password)
{
    var salt = RandomNumberGenerator.GetBytes(16);
    var hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, 100_000, HashAlgorithmName.SHA256, 32);
    return $"{Convert.ToBase64String(salt)}.{Convert.ToBase64String(hash)}";
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Infrastructure/Services/README.md"
# Infrastructure — Services

Integrations with external systems: email senders, SMS gateways, file
storage, HTTP clients, message brokers. Each external capability gets an
interface in Application and a concrete class here.

```csharp
public class SmtpEmailSender(ILogger<SmtpEmailSender> logger) : IEmailSender
{
    public Task SendAsync(string to, string subject, string body, CancellationToken ct = default)
    {
        logger.LogInformation("Sending email to {To}: {Subject}", to, subject);
        // ... real SMTP implementation
        return Task.CompletedTask;
    }
}
```
EOF

# API layer
cat <<'EOF' > "$PROJECT_NAME.Api/Controllers/README.md"
# API — Controllers

Thin HTTP endpoints. Controllers validate the request (model binding),
delegate to application services and translate results into HTTP status
codes. No business logic belongs here.

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductsController(IProductService service) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken ct) => Ok(await service.GetAllAsync(ct));
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Api/Middleware/README.md"
# API — Middleware

Custom middleware components running on every request: global exception
handling, request logging, correlation ids. Register them in `Program.cs`
with `app.Use...()`.

```csharp
public class ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try { await next(context); }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unhandled exception");
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            await context.Response.WriteAsJsonAsync(new { error = "An unexpected error occurred." });
        }
    }
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Api/Filters/README.md"
# API — Filters

ASP.NET Core action filters: cross-cutting checks around controller actions
(validation, caching headers, audit logging). They run inside the MVC
pipeline, before/after the action executes.

```csharp
public class ValidationFilter : IActionFilter
{
    public void OnActionExecuting(ActionExecutingContext context)
    {
        if (!context.ModelState.IsValid)
            context.Result = new BadRequestObjectResult(context.ModelState);
    }

    public void OnActionExecuted(ActionExecutedContext context) { }
}
```
EOF

cat <<'EOF' > "$PROJECT_NAME.Api/Extensions/README.md"
# API — Extensions

Extension-method helpers that keep `Program.cs` small, e.g. grouping
service registrations or pipeline configuration into readable methods.

```csharp
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<IUserService, UserService>();
        return services;
    }
}
```
EOF

# --- DOMAIN ---
cat <<'EOF' > "$PROJECT_NAME.Domain/Entities/AppUser.cs"
namespace __PROJECT_NAME__.Domain.Entities;

public class AppUser
{
    public Guid Id { get; set; }
    public string UserName { get; set; } = default!;
    public string Email { get; set; } = default!;
    public string PasswordHash { get; set; } = default!;
    public string Role { get; set; } = "User";
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Domain/Enums/Roles.cs"
namespace __PROJECT_NAME__.Domain.Enums;

public static class Roles
{
    public const string Admin = "Admin";
    public const string User  = "User";
}
EOF

# --- APPLICATION ---
cat <<'EOF' > "$PROJECT_NAME.Application/DTOs/UserDtos.cs"
namespace __PROJECT_NAME__.Application.DTOs;

public record UserDto(Guid Id, string UserName, string Email, string Role, bool IsActive);
public record CreateUserRequest(string UserName, string Email, string Password, string Role);
public record UpdateUserRequest(string UserName, string Email, string Role, bool IsActive);
public record LoginRequest(string UserName, string Password);
public record LoginResponse(string AccessToken, UserDto User);
EOF

cat <<'EOF' > "$PROJECT_NAME.Application/Interfaces/IUserRepository.cs"
using __PROJECT_NAME__.Domain.Entities;

namespace __PROJECT_NAME__.Application.Interfaces;

public interface IUserRepository
{
    Task<List<AppUser>> GetAllAsync(CancellationToken ct = default);
    Task<AppUser?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<AppUser?> GetByUserNameAsync(string userName, CancellationToken ct = default);
    Task AddAsync(AppUser user, CancellationToken ct = default);
    Task UpdateAsync(AppUser user, CancellationToken ct = default);
    Task DeleteAsync(AppUser user, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Application/Interfaces/IUserService.cs"
using __PROJECT_NAME__.Application.DTOs;

namespace __PROJECT_NAME__.Application.Interfaces;

public interface IUserService
{
    Task<IReadOnlyList<UserDto>> GetAllAsync(CancellationToken ct = default);
    Task<UserDto?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<UserDto> CreateAsync(CreateUserRequest request, CancellationToken ct = default);
    Task<UserDto?> UpdateAsync(Guid id, UpdateUserRequest request, CancellationToken ct = default);
    Task<bool> DeleteAsync(Guid id, CancellationToken ct = default);
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Application/Interfaces/IPasswordHasher.cs"
namespace __PROJECT_NAME__.Application.Interfaces;

public interface IPasswordHasher
{
    string Hash(string password);
    bool Verify(string password, string storedHash);
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Application/Interfaces/IJwtTokenService.cs"
using __PROJECT_NAME__.Domain.Entities;

namespace __PROJECT_NAME__.Application.Interfaces;

public interface IJwtTokenService
{
    string CreateToken(AppUser user);
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Application/Services/UserService.cs"
using __PROJECT_NAME__.Application.DTOs;
using __PROJECT_NAME__.Application.Interfaces;
using __PROJECT_NAME__.Domain.Entities;

namespace __PROJECT_NAME__.Application.Services;

public class UserService(IUserRepository repo, IPasswordHasher hasher) : IUserService
{
    public async Task<IReadOnlyList<UserDto>> GetAllAsync(CancellationToken ct = default)
        => (await repo.GetAllAsync(ct)).Select(MapToDto).ToList();

    public async Task<UserDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var user = await repo.GetByIdAsync(id, ct);
        return user is null ? null : MapToDto(user);
    }

    public async Task<UserDto> CreateAsync(CreateUserRequest request, CancellationToken ct = default)
    {
        var user = new AppUser
        {
            Id = Guid.NewGuid(),
            UserName = request.UserName,
            Email = request.Email,
            PasswordHash = hasher.Hash(request.Password),
            Role = request.Role
        };
        await repo.AddAsync(user, ct);
        await repo.SaveChangesAsync(ct);
        return MapToDto(user);
    }

    public async Task<UserDto?> UpdateAsync(Guid id, UpdateUserRequest request, CancellationToken ct = default)
    {
        var user = await repo.GetByIdAsync(id, ct);
        if (user is null) return null;

        user.UserName = request.UserName;
        user.Email = request.Email;
        user.Role = request.Role;
        user.IsActive = request.IsActive;

        await repo.UpdateAsync(user, ct);
        await repo.SaveChangesAsync(ct);
        return MapToDto(user);
    }

    public async Task<bool> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var user = await repo.GetByIdAsync(id, ct);
        if (user is null) return false;

        await repo.DeleteAsync(user, ct);
        await repo.SaveChangesAsync(ct);
        return true;
    }

    private static UserDto MapToDto(AppUser u) => new(u.Id, u.UserName, u.Email, u.Role, u.IsActive);
}
EOF

# --- INFRASTRUCTURE ---
cat <<'EOF' > "$PROJECT_NAME.Infrastructure/Persistence/AppDbContext.cs"
using Microsoft.EntityFrameworkCore;
using __PROJECT_NAME__.Domain.Entities;

namespace __PROJECT_NAME__.Infrastructure.Persistence;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<AppUser> Users => Set<AppUser>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AppUser>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.UserName).HasMaxLength(100).IsRequired();
            entity.HasIndex(x => x.UserName).IsUnique();
            entity.Property(x => x.Email).HasMaxLength(200).IsRequired();
            entity.Property(x => x.PasswordHash).IsRequired();
            entity.Property(x => x.Role).HasMaxLength(20).IsRequired();
        });
    }
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Infrastructure/Persistence/DbInitializer.cs"
using Microsoft.EntityFrameworkCore;
using __PROJECT_NAME__.Application.Interfaces;
using __PROJECT_NAME__.Domain.Entities;

namespace __PROJECT_NAME__.Infrastructure.Persistence;

/// <summary>
/// Applies migrations on startup and seeds a default admin user
/// (admin / __ADMIN_PASSWORD__) so the app is usable immediately.
/// </summary>
public static class DbInitializer
{
    public static async Task InitializeAsync(AppDbContext db, IPasswordHasher hasher, string adminEmail, CancellationToken ct = default)
    {
        await db.Database.MigrateAsync(ct);

        if (!await db.Users.AnyAsync(u => u.UserName == "admin", ct))
        {
            db.Users.Add(new AppUser
            {
                Id = Guid.NewGuid(),
                UserName = "admin",
                Email = adminEmail,
                PasswordHash = hasher.Hash("__ADMIN_PASSWORD__"),
                Role = "Admin",
                IsActive = true
            });
            await db.SaveChangesAsync(ct);
        }
    }
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Infrastructure/Repositories/UserRepository.cs"
using Microsoft.EntityFrameworkCore;
using __PROJECT_NAME__.Application.Interfaces;
using __PROJECT_NAME__.Domain.Entities;
using __PROJECT_NAME__.Infrastructure.Persistence;

namespace __PROJECT_NAME__.Infrastructure.Repositories;

public class UserRepository(AppDbContext db) : IUserRepository
{
    public Task<List<AppUser>> GetAllAsync(CancellationToken ct = default)
        => db.Users.AsNoTracking().OrderBy(x => x.UserName).ToListAsync(ct);

    public Task<AppUser?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => db.Users.FirstOrDefaultAsync(x => x.Id == id, ct);

    public Task<AppUser?> GetByUserNameAsync(string userName, CancellationToken ct = default)
        => db.Users.FirstOrDefaultAsync(x => x.UserName == userName, ct);

    public Task AddAsync(AppUser user, CancellationToken ct = default)
        => db.Users.AddAsync(user, ct).AsTask();

    public Task UpdateAsync(AppUser user, CancellationToken ct = default)
    {
        db.Users.Update(user);
        return Task.CompletedTask;
    }

    public Task DeleteAsync(AppUser user, CancellationToken ct = default)
    {
        db.Users.Remove(user);
        return Task.CompletedTask;
    }

    public Task SaveChangesAsync(CancellationToken ct = default)
        => db.SaveChangesAsync(ct);
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Infrastructure/Security/PasswordHasher.cs"
using System.Security.Cryptography;
using __PROJECT_NAME__.Application.Interfaces;

namespace __PROJECT_NAME__.Infrastructure.Security;

public class PasswordHasher : IPasswordHasher
{
    public string Hash(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(16);
        var hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, 100_000, HashAlgorithmName.SHA256, 32);
        return $"{Convert.ToBase64String(salt)}.{Convert.ToBase64String(hash)}";
    }

    public bool Verify(string password, string storedHash)
    {
        var parts = storedHash.Split('.', 2);
        if (parts.Length != 2) return false;

        var salt = Convert.FromBase64String(parts[0]);
        var expected = Convert.FromBase64String(parts[1]);
        var actual = Rfc2898DeriveBytes.Pbkdf2(password, salt, 100_000, HashAlgorithmName.SHA256, 32);

        return CryptographicOperations.FixedTimeEquals(actual, expected);
    }
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Infrastructure/Security/JwtTokenService.cs"
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using __PROJECT_NAME__.Application.Interfaces;
using __PROJECT_NAME__.Domain.Entities;

namespace __PROJECT_NAME__.Infrastructure.Security;

public sealed class JwtTokenService(IConfiguration config) : IJwtTokenService
{
    public string CreateToken(AppUser user)
    {
        var jwt = config.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.UserName),
            new Claim(ClaimTypes.Role, user.Role)
        };

        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(int.Parse(jwt["ExpiresMinutes"]!)),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
EOF

# --- API ---
cat <<'EOF' > "$PROJECT_NAME.Api/appsettings.json"
{
  "ConnectionStrings": {
    "DefaultConnection": "__CONN_STR__"
  },
  "Jwt": {
    "Key": "__JWT_KEY__",
    "Issuer": "__PROJECT_NAME__.Api",
    "Audience": "__PROJECT_NAME__.Angular",
    "ExpiresMinutes": 60
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Api/Properties/launchSettings.json"
{
  "profiles": {
    "http": {
      "commandName": "Project",
      "launchBrowser": false,
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      },
      "applicationUrl": "http://localhost:__API_PORT__"
    }
  }
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Api/Controllers/AuthController.cs"
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using __PROJECT_NAME__.Application.DTOs;
using __PROJECT_NAME__.Application.Interfaces;

namespace __PROJECT_NAME__.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController(IUserRepository users, IJwtTokenService tokens, IPasswordHasher hasher) : ControllerBase
{
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login(LoginRequest request, CancellationToken ct)
    {
        var user = await users.GetByUserNameAsync(request.UserName, ct);
        if (user is null || !hasher.Verify(request.Password, user.PasswordHash))
            return Unauthorized(new { message = "نام کاربری یا رمز عبور اشتباه است." });

        return Ok(new LoginResponse(
            tokens.CreateToken(user),
            new UserDto(user.Id, user.UserName, user.Email, user.Role, user.IsActive)));
    }
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Api/Controllers/UsersController.cs"
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using __PROJECT_NAME__.Application.DTOs;
using __PROJECT_NAME__.Application.Interfaces;
using __PROJECT_NAME__.Domain.Enums;

namespace __PROJECT_NAME__.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController(IUserService service) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken ct)
        => Ok(await service.GetAllAsync(ct));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var user = await service.GetByIdAsync(id, ct);
        return user is null ? NotFound() : Ok(user);
    }

    [HttpPost]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Create(CreateUserRequest request, CancellationToken ct)
    {
        var created = await service.CreateAsync(request, ct);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Update(Guid id, UpdateUserRequest request, CancellationToken ct)
    {
        var updated = await service.UpdateAsync(id, request, ct);
        return updated is null ? NotFound() : Ok(updated);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
        => await service.DeleteAsync(id, ct) ? NoContent() : NotFound();
}
EOF

cat <<'EOF' > "$PROJECT_NAME.Api/Program.cs"
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using __PROJECT_NAME__.Application.Interfaces;
using __PROJECT_NAME__.Application.Services;
using __PROJECT_NAME__.Infrastructure.Persistence;
using __PROJECT_NAME__.Infrastructure.Repositories;
using __PROJECT_NAME__.Infrastructure.Security;

var builder = WebApplication.CreateBuilder(args);

// ----- Database -----
builder.Services.AddDbContext<AppDbContext>(options =>
    __USE_DB__);

// ----- Dependency Injection (Clean Architecture) -----
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IPasswordHasher, PasswordHasher>();

builder.Services.AddControllers();

// ----- Swagger / OpenAPI (UI: /swagger) -----
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "__PROJECT_NAME__ API",
        Version = "v1",
        Description = "User Management CRUD API with JWT Authentication"
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        Description = "Enter your JWT token (without the 'Bearer ' prefix)."
    });

    // Swashbuckle 10.x style (Microsoft.OpenApi 2+/3+ API)
    options.AddSecurityRequirement(document =>
        new OpenApiSecurityRequirement
        {
            [new OpenApiSecuritySchemeReference("Bearer", document)] = []
        });
});

// ----- JWT Authentication -----
var jwt = builder.Configuration.GetSection("Jwt");
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwt["Issuer"],
            ValidAudience = jwt["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!)),
            RoleClaimType = System.Security.Claims.ClaimTypes.Role
        };
    });

builder.Services.AddAuthorization();

// ----- CORS (Angular dev server) -----
builder.Services.AddCors(options =>
{
    options.AddPolicy("frontend", policy =>
        policy.WithOrigins("http://localhost:4200")
              .AllowAnyHeader()
              .AllowAnyMethod());
});

var app = builder.Build();

// ----- Swagger UI: http://localhost:__API_PORT__/swagger -----
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "__PROJECT_NAME__ API v1");
    options.RoutePrefix = "swagger";
});

app.UseCors("frontend");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// ----- Health check -----
app.MapGet("/health", () => Results.Ok(new { status = "OK", service = "__PROJECT_NAME__ API" }));

// ----- Apply migrations automatically + seed default admin -----
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var hasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();
    await DbInitializer.InitializeAsync(db, hasher, "admin@__PROJECT_NAME_LOWER__.local");
}

app.Run();
EOF

# Apply placeholder substitution to every generated backend file
find "$PROJECT_NAME.Domain" "$PROJECT_NAME.Application" "$PROJECT_NAME.Infrastructure" "$PROJECT_NAME.Api" \
    \( -name "*.cs" -o -name "*.json" -o -name "*.md" \) -type f -not -path "*/obj/*" -not -path "*/bin/*" | while read -r f; do
    substitute "$f"
done

# ==========================================
# 2. BACKEND: BUILD & MIGRATIONS
# ==========================================
echo "🛠️  Building Backend..."
dotnet build >/dev/null || fail ".NET build failed. Check the output above with: dotnet build"

DOTNET_EF="dotnet ef"
if ! command -v dotnet-ef >/dev/null 2>&1; then
    echo " -> Installing dotnet-ef tool..."
    dotnet tool install --global dotnet-ef >/dev/null 2>&1 \
        || dotnet tool update --global dotnet-ef >/dev/null 2>&1 \
        || fail "dotnet-ef tool install failed."
    [ -f "$HOME/.dotnet/tools/dotnet-ef.exe" ] && DOTNET_EF="$HOME/.dotnet/tools/dotnet-ef.exe"
fi

echo "🗄️  Creating EF Core Migration..."
$DOTNET_EF migrations add InitialCreate \
    --project "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" \
    --startup-project "$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj" \
    || fail "EF migration creation failed. Run it manually to see the error."

echo "🗄️  Updating Database ($DB_TYPE @ $DB_HOST:$DB_PORT -> $DB_NAME)..."
if $DOTNET_EF database update \
    --project "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" \
    --startup-project "$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj"; then
    echo "✅ Database created/updated successfully."
else
    warn "Database update failed. The API will retry automatically on startup."
fi

# ==========================================
# 3. FRONTEND: ANGULAR 22 + TAILWIND CSS v4
# ==========================================
echo "🅰️  Creating Angular Frontend (this takes 2-4 minutes)..."

if ! command -v ng >/dev/null 2>&1; then
    echo " -> Installing Angular CLI..."
    npm install -g @angular/cli --no-fund --no-audit || fail "Angular CLI install failed."
fi

ng new "$UI_NAME" --routing --style=css --ssr=false --zoneless --skip-git --defaults --package-manager=npm \
    || fail "ng new failed."

cd "$UI_NAME" || fail "Cannot enter $UI_NAME."

echo " -> Installing Tailwind CSS v4..."
npm install tailwindcss @tailwindcss/postcss postcss --no-fund --no-audit \
    || fail "Tailwind CSS install failed."

# Remove ng new's default app files (works for both old and new CLI naming)
rm -f src/app/app.ts src/app/app.html src/app/app.css src/app/app.spec.ts \
      src/app/app.config.ts src/app/app.routes.ts \
      src/app/app.component.ts src/app/app.component.html src/app/app.component.css src/app/app.component.spec.ts

mkdir -p src/environments src/app/models src/app/services src/app/interceptors src/app/guards src/app/pages/login src/app/pages/users

# Tailwind CSS v4: register the PostCSS plugin (required, otherwise classes are NOT generated)
cat <<'EOF' > .postcssrc.json
{
  "plugins": {
    "@tailwindcss/postcss": {}
  }
}
EOF

cat <<'EOF' > src/styles.css
@import 'tailwindcss';

html, body {
  direction: rtl;
  font-family: "Vazirmatn", "Segoe UI", Tahoma, Arial, sans-serif;
}
EOF

cat <<'EOF' > src/index.html
<!doctype html>
<html lang="fa" dir="rtl">
<head>
  <meta charset="utf-8">
  <title>__PROJECT_NAME__</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.ico">
</head>
<body>
  <app-root></app-root>
</body>
</html>
EOF

cat <<'EOF' > src/main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';

bootstrapApplication(AppComponent, appConfig)
  .catch((err) => console.error(err));
EOF

cat <<'EOF' > src/environments/environment.ts
export const environment = {
  production: false,
  apiUrl: 'http://localhost:__API_PORT__/api'
};
EOF

cat <<'EOF' > src/app/models/user.model.ts
export interface User {
  id: string;
  userName: string;
  email: string;
  role: 'Admin' | 'User';
  isActive: boolean;
}

export interface LoginRequest {
  userName: string;
  password: string;
}

export interface LoginResponse {
  accessToken: string;
  user: User;
}
EOF

cat <<'EOF' > src/app/services/auth.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { tap } from 'rxjs/operators';
import { LoginRequest, LoginResponse } from '../models/user.model';
import { environment } from '../../environments/environment';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  private tokenKey = 'access_token';

  login(payload: LoginRequest) {
    return this.http.post<LoginResponse>(`${environment.apiUrl}/auth/login`, payload)
      .pipe(tap(res => localStorage.setItem(this.tokenKey, res.accessToken)));
  }

  logout() {
    localStorage.removeItem(this.tokenKey);
  }

  get token(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  isLoggedIn(): boolean {
    return !!this.token;
  }
}
EOF

cat <<'EOF' > src/app/services/user.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { User } from '../models/user.model';
import { environment } from '../../environments/environment';

@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  private url = `${environment.apiUrl}/users`;

  getAll() {
    return this.http.get<User[]>(this.url);
  }

  create(p: { userName: string; email: string; password: string; role: 'Admin' | 'User' }) {
    return this.http.post<User>(this.url, p);
  }

  update(id: string, p: { userName: string; email: string; role: 'Admin' | 'User'; isActive: boolean }) {
    return this.http.put<User>(`${this.url}/${id}`, p);
  }

  delete(id: string) {
    return this.http.delete(`${this.url}/${id}`);
  }
}
EOF

cat <<'EOF' > src/app/interceptors/auth.interceptor.ts
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = inject(AuthService).token;
  if (!token) return next(req);
  return next(req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }));
};
EOF

cat <<'EOF' > src/app/guards/auth.guard.ts
import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return auth.isLoggedIn() ? true : router.createUrlTree(['/login']);
};
EOF

cat <<'EOF' > src/app/app.routes.ts
import { Routes } from '@angular/router';
import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
  { path: 'login', loadComponent: () => import('./pages/login/login.component').then(m => m.LoginComponent) },
  { path: 'users', canActivate: [authGuard], loadComponent: () => import('./pages/users/users.component').then(m => m.UsersComponent) },
  { path: '', pathMatch: 'full', redirectTo: 'users' },
  { path: '**', redirectTo: 'users' }
];
EOF

# app.config.ts — zone-aware: Angular 17-20 templates ship zone.js, Angular 21+ is zoneless.
if grep -q '"zone.js"' package.json; then
cat <<'EOF' > src/app/app.config.ts
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { routes } from './app.routes';
import { authInterceptor } from './interceptors/auth.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor]))
  ]
};
EOF
else
cat <<'EOF' > src/app/app.config.ts
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { routes } from './app.routes';
import { authInterceptor } from './interceptors/auth.interceptor';

// Zoneless change detection (Angular 21+ default): no zone.js provider is needed.
export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor]))
  ]
};
EOF
fi

cat <<'EOF' > src/app/app.component.ts
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  template: `<router-outlet></router-outlet>`,
})
export class AppComponent {}
EOF

cat <<'EOF' > src/app/pages/login/login.component.ts
import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  imports: [FormsModule],
  template: `
    <div class="flex min-h-screen items-center justify-center bg-slate-100 px-4">
      <form (ngSubmit)="login()" class="w-full max-w-sm rounded-2xl bg-white p-8 shadow-lg">
        <h2 class="mb-6 text-center text-2xl font-bold text-slate-800">ورود به سیستم</h2>

        <input [(ngModel)]="userName" name="userName" placeholder="نام کاربری"
               class="mb-4 w-full rounded-lg border border-slate-300 p-2.5 focus:border-blue-500 focus:outline-none" />

        <input [(ngModel)]="password" name="password" type="password" placeholder="رمز عبور"
               class="mb-4 w-full rounded-lg border border-slate-300 p-2.5 focus:border-blue-500 focus:outline-none" />

        @if (error()) {
          <p class="mb-4 rounded-lg bg-red-50 p-2 text-center text-sm text-red-600">{{ error() }}</p>
        }

        <button type="submit" [disabled]="loading()"
                class="w-full rounded-lg bg-blue-600 p-2.5 text-white transition hover:bg-blue-700 disabled:opacity-50">
          {{ loading() ? 'در حال ورود...' : 'ورود' }}
        </button>

        <div class="mt-6 rounded-lg bg-slate-50 p-3 text-center text-xs text-slate-500">
          کاربر پیش‌فرض: admin / Admin&#64;__ADMIN_PASSWORD__
        </div>
      </form>
    </div>`
})
export class LoginComponent {
  private auth = inject(AuthService);
  private router = inject(Router);

  userName = '';
  password = '';
  loading = signal(false);
  error = signal('');

  login(): void {
    if (this.loading()) return;
    this.loading.set(true);
    this.error.set('');

    this.auth.login({ userName: this.userName, password: this.password }).subscribe({
      next: () => this.router.navigate(['/users']),
      error: () => {
        this.error.set('نام کاربری یا رمز عبور اشتباه است');
        this.loading.set(false);
      }
    });
  }
}
EOF

cat <<'EOF' > src/app/pages/users/users.component.ts
import { Component, inject, OnInit, signal } from '@angular/core';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { UserService } from '../../services/user.service';
import { AuthService } from '../../services/auth.service';
import { User } from '../../models/user.model';

@Component({
  selector: 'app-users',
  imports: [ReactiveFormsModule],
  template: `
    <div class="min-h-screen bg-slate-100">
      <header class="bg-white shadow">
        <div class="mx-auto flex max-w-4xl items-center justify-between px-4 py-4">
          <h1 class="text-lg font-bold text-slate-800">مدیریت کاربران</h1>
          <button (click)="logout()"
                  class="rounded-lg bg-slate-200 px-4 py-1.5 text-sm text-slate-700 transition hover:bg-slate-300">خروج</button>
        </div>
      </header>

      <main class="mx-auto max-w-4xl px-4 py-8">
        <form [formGroup]="form" (ngSubmit)="submit()"
              class="mb-8 grid grid-cols-1 gap-4 rounded-2xl bg-white p-6 shadow sm:grid-cols-2">
          <input formControlName="userName" placeholder="نام کاربری"
                 class="rounded-lg border border-slate-300 p-2.5 focus:border-blue-500 focus:outline-none" />
          <input formControlName="email" placeholder="ایمیل"
                 class="rounded-lg border border-slate-300 p-2.5 focus:border-blue-500 focus:outline-none" />
          <input type="password" formControlName="password" placeholder="رمز عبور"
                 class="rounded-lg border border-slate-300 p-2.5 focus:border-blue-500 focus:outline-none" />
          <select formControlName="role"
                  class="rounded-lg border border-slate-300 p-2.5 focus:border-blue-500 focus:outline-none">
            <option value="User">User</option>
            <option value="Admin">Admin</option>
          </select>
          <label class="flex items-center gap-2 text-sm text-slate-700 sm:col-span-2">
            <input type="checkbox" formControlName="isActive" class="h-4 w-4" />
            کاربر فعال
          </label>
          <div class="flex gap-2 sm:col-span-2">
            <button type="submit"
                    class="rounded-lg bg-green-600 px-6 py-2 text-white transition hover:bg-green-700">
              {{ editingId() ? 'بروزرسانی' : 'افزودن کاربر' }}
            </button>
            @if (editingId()) {
              <button type="button" (click)="cancelEdit()"
                      class="rounded-lg bg-slate-200 px-6 py-2 text-slate-700 transition hover:bg-slate-300">انصراف</button>
            }
          </div>
        </form>

        <div class="overflow-hidden rounded-2xl bg-white shadow">
          <table class="w-full text-right text-sm">
            <thead class="bg-slate-50 text-slate-600">
              <tr>
                <th class="p-4 font-medium">نام کاربری</th>
                <th class="p-4 font-medium">ایمیل</th>
                <th class="p-4 font-medium">نقش</th>
                <th class="p-4 font-medium">وضعیت</th>
                <th class="p-4 font-medium">عملیات</th>
              </tr>
            </thead>
            <tbody>
              @for (u of users(); track u.id) {
                <tr class="border-t border-slate-100 hover:bg-slate-50">
                  <td class="p-4 font-medium text-slate-800">{{ u.userName }}</td>
                  <td class="p-4 text-slate-600">{{ u.email }}</td>
                  <td class="p-4">
                    <span
                      [class]="u.role === 'Admin'
                        ? 'rounded-full bg-purple-100 px-2.5 py-0.5 text-xs text-purple-700'
                        : 'rounded-full bg-blue-100 px-2.5 py-0.5 text-xs text-blue-700'">
                      {{ u.role }}
                    </span>
                  </td>
                  <td class="p-4">
                    <span
                      [class]="u.isActive
                        ? 'inline-block h-2.5 w-2.5 rounded-full bg-green-500'
                        : 'inline-block h-2.5 w-2.5 rounded-full bg-red-400'">
                    </span>
                  </td>
                  <td class="p-4">
                    <div class="flex gap-2">
                      <button (click)="edit(u)"
                              class="rounded-lg bg-blue-500 px-3 py-1.5 text-xs text-white transition hover:bg-blue-600">ویرایش</button>
                      <button (click)="remove(u.id)"
                              class="rounded-lg bg-red-500 px-3 py-1.5 text-xs text-white transition hover:bg-red-600">حذف</button>
                    </div>
                  </td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="5" class="p-8 text-center text-slate-400">کاربری یافت نشد</td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </main>
    </div>`
})
export class UsersComponent implements OnInit {
  private api = inject(UserService);
  private auth = inject(AuthService);
  private router = inject(Router);

  users = signal<User[]>([]);
  editingId = signal<string | null>(null);

  form = new FormGroup({
    userName: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    email: new FormControl('', { nonNullable: true, validators: [Validators.required, Validators.email] }),
    password: new FormControl('', { nonNullable: true }),
    role: new FormControl<'Admin' | 'User'>('User', { nonNullable: true }),
    isActive: new FormControl(true, { nonNullable: true })
  });

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.api.getAll().subscribe(data => this.users.set(data));
  }

  submit(): void {
    if (this.form.invalid) return;
    const v = this.form.getRawValue();
    const id = this.editingId();

    const request$ = id
      ? this.api.update(id, { userName: v.userName, email: v.email, role: v.role, isActive: v.isActive })
      : this.api.create({ userName: v.userName, email: v.email, password: v.password, role: v.role });

    request$.subscribe(() => {
      this.editingId.set(null);
      this.form.reset({ role: 'User', isActive: true });
      this.load();
    });
  }

  edit(u: User): void {
    this.editingId.set(u.id);
    this.form.patchValue({ userName: u.userName, email: u.email, role: u.role, isActive: u.isActive, password: '' });
  }

  cancelEdit(): void {
    this.editingId.set(null);
    this.form.reset({ role: 'User', isActive: true });
  }

  remove(id: string): void {
    if (confirm('این کاربر حذف شود؟')) {
      this.api.delete(id).subscribe(() => this.load());
    }
  }

  logout(): void {
    this.auth.logout();
    this.router.navigate(['/login']);
  }
}
EOF

substitute src/index.html
substitute src/environments/environment.ts
substitute src/app/pages/login/login.component.ts

echo "🔨 Building Angular App..."
npm run build || fail "Angular build failed. Check the output above with: npm run build"
cd ..

# ==========================================
# 4. SMOKE TEST (Backend)
# ==========================================
echo "🧪 Running Backend Smoke Test..."
SMOKE_SKIPPED=0
if (echo > "/dev/tcp/localhost/$API_PORT") >/dev/null 2>&1; then
    warn "Port $API_PORT is already in use — skipping smoke test (an API instance may be running)."
    SMOKE_SKIPPED=1
fi

if [ "$SMOKE_SKIPPED" = "0" ]; then
    TFM_DIR=$(ls "$PROJECT_NAME.Api/bin/Debug" 2>/dev/null | head -n1)
    API_DLL="$PWD/$PROJECT_NAME.Api/bin/Debug/$TFM_DIR/$PROJECT_NAME.Api.dll"
    SMOKE_LOG="/tmp/${PROJECT_NAME_LOWER}_api_smoke.log"

    if [ -f "$API_DLL" ]; then
        # Run the DLL from the Api directory so appsettings.json (ContentRoot) is found
        cd "$PROJECT_NAME.Api" || true
        ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS="http://localhost:$API_PORT" \
            dotnet "$API_DLL" > "$SMOKE_LOG" 2>&1 &
        API_PID=$!

        HEALTH_OK=0
        for _ in $(seq 1 30); do
            if curl -sf "http://localhost:$API_PORT/health" >/dev/null 2>&1; then HEALTH_OK=1; break; fi
            sleep 1
        done

        if [ "$HEALTH_OK" = "1" ]; then
            SWAGGER_JSON=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$API_PORT/swagger/v1/swagger.json")
            SWAGGER_UI=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$API_PORT/swagger/index.html")
            LOGIN_HTTP=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://localhost:$API_PORT/api/auth/login" \
                -H 'Content-Type: application/json' -d "{\"userName\":\"$ADMIN_USER\",\"password\":\"$ADMIN_PASSWORD\"}")
            echo "   /health                  : $HEALTH_OK  (1 = OK)"
            echo "   /swagger/v1/swagger.json : $SWAGGER_JSON  (200 = OK)"
            echo "   /swagger/index.html      : $SWAGGER_UI  (200 = OK)"
            echo "   POST /api/auth/login     : $LOGIN_HTTP  (200 = OK)"
        else
            warn "API did not start within 30s. See log: $SMOKE_LOG"
        fi

        kill "$API_PID" 2>/dev/null
        sleep 1
        cd .. || true
    else
        warn "API DLL not found — skipping smoke test."
    fi
fi

# ==========================================
# 5. README
# ==========================================
cat <<'EOF' > README.md
# __PROJECT_NAME__

Full-Stack CRUD app generated from the Clean Architecture template.

## Stack
- **Backend**: .NET 10 Web API — Clean Architecture (Domain / Application / Infrastructure / Api)
  - JWT Authentication, Swagger UI, EF Core migrations (auto-applied on startup)
- **Frontend**: Angular (standalone, zoneless) + Tailwind CSS v4 + RTL Persian UI
- **Database**: __DB_TYPE__

## Run

### Backend — API on http://localhost:__API_PORT__
```bash
cd __PROJECT_NAME__.__API_ABBR__
dotnet run
```

### Frontend — http://localhost:4200
```bash
cd __PROJECT_NAME_LOWER__-ui
ng serve
```

## URLs
| What | URL |
|---|---|
| API | http://localhost:__API_PORT__ |
| Swagger UI | http://localhost:__API_PORT__/swagger |
| Frontend | http://localhost:4200 |

## Default Admin (seeded automatically on first API start)
| Username | Password | Role |
|---|---|---|
| admin | __ADMIN_PASSWORD__ | Admin |

## Notes
- Migrations are in `__PROJECT_NAME__.Infrastructure/Migrations` and are applied automatically when the API starts.
- The JWT signing key was generated randomly into `__PROJECT_NAME__.__API_ABBR__/appsettings.json`.
EOF

sed -i "s|__API_ABBR__|Api|g; s|__DB_TYPE__|$(escape_repl "$DB_TYPE")|g" README.md
substitute README.md

# ==========================================
# DONE
# ==========================================
echo ""
echo "=================================================="
echo "✅ Project Generation Complete!"
echo "=================================================="
echo "  Backend : cd $PROJECT_NAME/$PROJECT_NAME.Api && dotnet run"
echo "  API     : http://localhost:$API_PORT"
echo "  Swagger : http://localhost:$API_PORT/swagger"
echo "  Frontend: cd $PROJECT_NAME/$UI_NAME && ng serve  ->  http://localhost:4200"
echo "  Admin   : $ADMIN_USER / $ADMIN_PASSWORD"
echo "  DB      : $DB_TYPE @ $DB_HOST:$DB_PORT -> $DB_NAME"
echo "=================================================="
