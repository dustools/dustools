# Building a Complete User Management System with .NET 10, ASP.NET Core, PostgreSQL, EF Core, JWT, Swagger, Angular 22, and Tailwind CSS v4

A complete, end-to-end tutorial with every backend and frontend piece included.

> **Verification baseline:** This guide targets **.NET 10 / ASP.NET Core 10**, **Entity Framework Core 10**, **Angular 22**, **PostgreSQL**, **JWT Bearer authentication**, **Swashbuckle.AspNetCore 10.2.3**, and **Tailwind CSS v4 with the official Angular/PostCSS setup**.
>
> As of September 2026, .NET 10 is the active LTS release, with the latest patch listed by Microsoft as 10.0.12 on September 8, 2026. Angular 22 is actively supported. citeturn900177search0turn844149search0

---

## 1. What We Are Building

We will build a small but complete **User Management System**.

The application supports:

- User registration through an Admin-only endpoint
- User login
- JWT access tokens
- Role-based authorization
- User listing
- User details
- User creation
- User update
- User deletion
- PostgreSQL persistence
- EF Core migrations
- Swagger UI for API testing
- Angular standalone frontend
- Angular route guard
- Functional HTTP interceptor
- Reactive Forms
- Tailwind CSS v4

The final architecture is:

```text
Angular 22 + Tailwind CSS
        |
        | HTTP + JWT
        v
ASP.NET Core 10 Web API
        |
        +--> Controllers
        |
        +--> Application
        |      |
        |      +--> DTOs
        |      +--> Services
        |      +--> Interfaces
        |
        +--> Infrastructure
               |
               +--> EF Core
               +--> PostgreSQL
               +--> JWT
               +--> Password hashing
```

The request flow is:

```text
Login form
    |
    v
POST /api/auth/login
    |
    v
ASP.NET Core validates credentials
    |
    v
JWT access token
    |
    v
Angular stores token
    |
    v
HTTP interceptor adds:
Authorization: Bearer <token>
    |
    v
ASP.NET Core validates JWT
    |
    v
Controller
    |
    v
Application service
    |
    v
Repository
    |
    v
EF Core
    |
    v
PostgreSQL
```

---

# 2. Technology Stack

## Backend

| Technology | Version / choice |
|---|---|
| .NET | 10 LTS |
| ASP.NET Core | 10 |
| EF Core | 10 |
| PostgreSQL | Current supported release |
| Npgsql EF Core Provider | 10.x |
| JWT Bearer | 10.x |
| Swagger/OpenAPI UI | Swashbuckle.AspNetCore 10.2.3 |

## Frontend

| Technology | Version / choice |
|---|---|
| Angular | 22 |
| TypeScript | Angular 22 compatible range |
| Node.js | Angular 22 supported range |
| Tailwind CSS | v4 |
| PostCSS | v4-compatible setup |

Angular 22's current compatibility table lists Node.js 22.22.x / 24.15.x / 26.x, TypeScript 5.9.x and the supported RxJS ranges. Always check the Angular compatibility table before starting a new project. citeturn844149search0

---

# 3. Clean Architecture

We use four backend projects:

```text
UserManagement.Domain
UserManagement.Application
UserManagement.Infrastructure
UserManagement.Api
```

The dependency graph is:

```text
Api
 |
 +----> Infrastructure
 |
 +----> Application
           |
           +----> Domain

Infrastructure
 |
 +----> Application
 |
 +----> Domain
```

The important rule is:

> Business logic should not depend on PostgreSQL, EF Core, HTTP, Angular, or other infrastructure details.

The layers have these responsibilities.

### Domain

Contains:

- Entities
- Domain constants
- Pure business concepts

### Application

Contains:

- DTOs
- Use cases
- Business services
- Interfaces for repositories and infrastructure abstractions

### Infrastructure

Contains:

- DbContext
- EF Core configuration
- Repository implementations
- Password hashing implementation
- JWT implementation
- Database seeding

### API

Contains:

- Controllers
- Dependency injection registration
- Authentication middleware
- CORS
- Swagger
- Application startup

---

# 4. Final Project Structure

The finished repository should look approximately like this:

```text
UserManagement/
|
+-- UserManagement.sln
|
+-- UserManagement.Domain/
|   +-- Entities/
|   |   +-- AppUser.cs
|   |
|   +-- Constants/
|       +-- Roles.cs
|
+-- UserManagement.Application/
|   +-- DTOs/
|   |   +-- Auth/
|   |   |   +-- LoginRequest.cs
|   |   |   +-- LoginResponse.cs
|   |   |
|   |   +-- Users/
|   |       +-- UserDto.cs
|   |       +-- CreateUserRequest.cs
|   |       +-- UpdateUserRequest.cs
|   |
|   +-- Interfaces/
|   |   +-- IUserRepository.cs
|   |   +-- IUserService.cs
|   |   +-- IJwtTokenService.cs
|   |   +-- IPasswordHasher.cs
|   |
|   +-- Services/
|       +-- UserService.cs
|
+-- UserManagement.Infrastructure/
|   +-- Persistence/
|   |   +-- AppDbContext.cs
|   |   +-- DatabaseSeeder.cs
|   |
|   +-- Repositories/
|   |   +-- UserRepository.cs
|   |
|   +-- Security/
|       +-- JwtOptions.cs
|       +-- JwtTokenService.cs
|       +-- PasswordHasher.cs
|
+-- UserManagement.Api/
    +-- Controllers/
    |   +-- AuthController.cs
    |   +-- UsersController.cs
    |
    +-- appsettings.json
    +-- appsettings.Development.json
    +-- Program.cs
```

Angular:

```text
user-management-ui/
|
+-- src/
    +-- app/
    |   +-- core/
    |   |   +-- models/
    |   |   |   +-- auth.models.ts
    |   |   |   +-- user.models.ts
    |   |   |
    |   |   +-- services/
    |   |   |   +-- auth.service.ts
    |   |   |   +-- user.service.ts
    |   |   |
    |   |   +-- guards/
    |   |   |   +-- auth.guard.ts
    |   |   |
    |   |   +-- interceptors/
    |   |       +-- auth.interceptor.ts
    |   |
    |   +-- pages/
    |       +-- login/
    |       |   +-- login.component.ts
    |       |   +-- login.component.html
    |       |
    |       +-- users/
    |           +-- users.component.ts
    |           +-- users.component.html
    |
    +-- app.config.ts
    +-- app.routes.ts
    +-- environments/
        +-- environment.ts
        +-- environment.development.ts
```

---

# 5. Create the .NET Solution

Make sure .NET 10 SDK is installed:

```bash
dotnet --version
```

Create the solution:

```bash
mkdir UserManagement
cd UserManagement

dotnet new sln -n UserManagement
```

Create projects:

```bash
dotnet new classlib -n UserManagement.Domain
dotnet new classlib -n UserManagement.Application
dotnet new classlib -n UserManagement.Infrastructure
dotnet new webapi -n UserManagement.Api --framework net10.0
```

Add them to the solution:

```bash
dotnet sln add UserManagement.Domain
dotnet sln add UserManagement.Application
dotnet sln add UserManagement.Infrastructure
dotnet sln add UserManagement.Api
```

Add references:

```bash
dotnet add UserManagement.Application reference UserManagement.Domain

dotnet add UserManagement.Infrastructure reference UserManagement.Application
dotnet add UserManagement.Infrastructure reference UserManagement.Domain

dotnet add UserManagement.Api reference UserManagement.Application
dotnet add UserManagement.Api reference UserManagement.Infrastructure
```

Build:

```bash
dotnet build
```

---

# 6. Backend Package Versions

For a reproducible .NET 10 tutorial, pin the current stable package family rather than mixing major versions.

As of September 8, 2026:

- Microsoft.EntityFrameworkCore: 10.0.12
- Microsoft.EntityFrameworkCore.Design: 10.0.12
- Microsoft.AspNetCore.Authentication.JwtBearer: 10.0.12
- Npgsql.EntityFrameworkCore.PostgreSQL: 10.0.3
- Swashbuckle.AspNetCore: 10.2.3

The versions are compatible with .NET 10. citeturn880267search1turn880267search0turn900177search4turn880267search7turn744190search1

Install them:

```bash
dotnet add UserManagement.Infrastructure package Microsoft.EntityFrameworkCore --version 10.0.12

dotnet add UserManagement.Infrastructure package Microsoft.EntityFrameworkCore.Design --version 10.0.12

dotnet add UserManagement.Infrastructure package Npgsql.EntityFrameworkCore.PostgreSQL --version 10.0.3

dotnet add UserManagement.Infrastructure package Microsoft.AspNetCore.Authentication.JwtBearer --version 10.0.12

dotnet add UserManagement.Api package Swashbuckle.AspNetCore --version 10.2.3
```

`Microsoft.EntityFrameworkCore.Design` is the EF Core design-time package used by migration tooling. citeturn880267search0

---

# 7. Domain Layer

## 7.1 AppUser.cs

Create:

```text
UserManagement.Domain/Entities/AppUser.cs
```

```csharp
namespace UserManagement.Domain.Entities;

public sealed class AppUser
{
    public Guid Id { get; set; }

    public string UserName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string PasswordHash { get; set; } = string.Empty;

    public string Role { get; set; } = string.Empty;

    public bool IsActive { get; set; }

    public DateTime CreatedAtUtc { get; set; }
}
```

The entity deliberately contains `PasswordHash`, not a raw password.

---

## 7.2 Roles.cs

Create:

```text
UserManagement.Domain/Constants/Roles.cs
```

```csharp
namespace UserManagement.Domain.Constants;

public static class Roles
{
    public const string Admin = "Admin";
    public const string User = "User";
}
```

---

# 8. Application Layer

## 8.1 UserDto.cs

Create:

```text
UserManagement.Application/DTOs/Users/UserDto.cs
```

```csharp
namespace UserManagement.Application.DTOs.Users;

public sealed record UserDto(
    Guid Id,
    string UserName,
    string Email,
    string Role,
    bool IsActive,
    DateTime CreatedAtUtc);
```

---

## 8.2 CreateUserRequest.cs

```text
UserManagement.Application/DTOs/Users/CreateUserRequest.cs
```

```csharp
using System.ComponentModel.DataAnnotations;

namespace UserManagement.Application.DTOs.Users;

public sealed record CreateUserRequest(
    [property: Required]
    [property: StringLength(100, MinimumLength = 3)]
    string UserName,

    [property: Required]
    [property: EmailAddress]
    [property: StringLength(200)]
    string Email,

    [property: Required]
    [property: StringLength(100, MinimumLength = 8)]
    string Password,

    [property: Required]
    string Role);
```

---

## 8.3 UpdateUserRequest.cs

```text
UserManagement.Application/DTOs/Users/UpdateUserRequest.cs
```

```csharp
using System.ComponentModel.DataAnnotations;

namespace UserManagement.Application.DTOs.Users;

public sealed record UpdateUserRequest(
    [property: Required]
    [property: StringLength(100, MinimumLength = 3)]
    string UserName,

    [property: Required]
    [property: EmailAddress]
    [property: StringLength(200)]
    string Email,

    [property: Required]
    string Role,

    bool IsActive);
```

---

## 8.4 LoginRequest.cs

```text
UserManagement.Application/DTOs/Auth/LoginRequest.cs
```

```csharp
using System.ComponentModel.DataAnnotations;

namespace UserManagement.Application.DTOs.Auth;

public sealed record LoginRequest(
    [property: Required]
    string UserName,

    [property: Required]
    string Password);
```

---

## 8.5 LoginResponse.cs

```text
UserManagement.Application/DTOs/Auth/LoginResponse.cs
```

```csharp
using UserManagement.Application.DTOs.Users;

namespace UserManagement.Application.DTOs.Auth;

public sealed record LoginResponse(
    string AccessToken,
    UserDto User);
```

---

# 9. Application Interfaces

## 9.1 IUserRepository.cs

```text
UserManagement.Application/Interfaces/IUserRepository.cs
```

```csharp
using UserManagement.Domain.Entities;

namespace UserManagement.Application.Interfaces;

public interface IUserRepository
{
    Task<IReadOnlyList<AppUser>> GetAllAsync(
        CancellationToken cancellationToken = default);

    Task<AppUser?> GetByIdAsync(
        Guid id,
        CancellationToken cancellationToken = default);

    Task<AppUser?> GetByUserNameAsync(
        string userName,
        CancellationToken cancellationToken = default);

    Task<AppUser?> GetByEmailAsync(
        string email,
        CancellationToken cancellationToken = default);

    Task AddAsync(
        AppUser user,
        CancellationToken cancellationToken = default);

    Task DeleteAsync(
        AppUser user,
        CancellationToken cancellationToken = default);

    Task SaveChangesAsync(
        CancellationToken cancellationToken = default);
}
```

---

## 9.2 IUserService.cs

```text
UserManagement.Application/Interfaces/IUserService.cs
```

```csharp
using UserManagement.Application.DTOs.Users;

namespace UserManagement.Application.Interfaces;

public interface IUserService
{
    Task<IReadOnlyList<UserDto>> GetAllAsync(
        CancellationToken cancellationToken = default);

    Task<UserDto?> GetByIdAsync(
        Guid id,
        CancellationToken cancellationToken = default);

    Task<UserDto> CreateAsync(
        CreateUserRequest request,
        CancellationToken cancellationToken = default);

    Task<UserDto?> UpdateAsync(
        Guid id,
        UpdateUserRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(
        Guid id,
        CancellationToken cancellationToken = default);
}
```

---

## 9.3 IPasswordHasher.cs

```text
UserManagement.Application/Interfaces/IPasswordHasher.cs
```

```csharp
namespace UserManagement.Application.Interfaces;

public interface IPasswordHasher
{
    string Hash(string password);

    bool Verify(
        string password,
        string passwordHash);
}
```

---

## 9.4 IJwtTokenService.cs

```text
UserManagement.Application/Interfaces/IJwtTokenService.cs
```

```csharp
using UserManagement.Domain.Entities;

namespace UserManagement.Application.Interfaces;

public interface IJwtTokenService
{
    string CreateToken(AppUser user);
}
```

---

# 10. The Missing Piece: UserService.cs

This is the central application service.

Create:

```text
UserManagement.Application/Services/UserService.cs
```

```csharp
using UserManagement.Application.DTOs.Users;
using UserManagement.Application.Interfaces;
using UserManagement.Domain.Constants;
using UserManagement.Domain.Entities;

namespace UserManagement.Application.Services;

public sealed class UserService(
    IUserRepository repository,
    IPasswordHasher passwordHasher)
    : IUserService
{
    public async Task<IReadOnlyList<UserDto>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        var users =
            await repository.GetAllAsync(cancellationToken);

        return users
            .Select(Map)
            .ToList();
    }

    public async Task<UserDto?> GetByIdAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var user =
            await repository.GetByIdAsync(
                id,
                cancellationToken);

        return user is null
            ? null
            : Map(user);
    }

    public async Task<UserDto> CreateAsync(
        CreateUserRequest request,
        CancellationToken cancellationToken = default)
    {
        ValidateRole(request.Role);

        var normalizedUserName =
            request.UserName.Trim();

        var normalizedEmail =
            request.Email.Trim().ToLowerInvariant();

        var existingUserName =
            await repository.GetByUserNameAsync(
                normalizedUserName,
                cancellationToken);

        if (existingUserName is not null)
        {
            throw new InvalidOperationException(
                "Username is already in use.");
        }

        var existingEmail =
            await repository.GetByEmailAsync(
                normalizedEmail,
                cancellationToken);

        if (existingEmail is not null)
        {
            throw new InvalidOperationException(
                "Email is already in use.");
        }

        var user = new AppUser
        {
            Id = Guid.NewGuid(),
            UserName = normalizedUserName,
            Email = normalizedEmail,
            PasswordHash =
                passwordHasher.Hash(request.Password),
            Role = request.Role,
            IsActive = true,
            CreatedAtUtc = DateTime.UtcNow
        };

        await repository.AddAsync(
            user,
            cancellationToken);

        await repository.SaveChangesAsync(
            cancellationToken);

        return Map(user);
    }

    public async Task<UserDto?> UpdateAsync(
        Guid id,
        UpdateUserRequest request,
        CancellationToken cancellationToken = default)
    {
        ValidateRole(request.Role);

        var user =
            await repository.GetByIdAsync(
                id,
                cancellationToken);

        if (user is null)
        {
            return null;
        }

        var normalizedUserName =
            request.UserName.Trim();

        var normalizedEmail =
            request.Email.Trim().ToLowerInvariant();

        var userNameOwner =
            await repository.GetByUserNameAsync(
                normalizedUserName,
                cancellationToken);

        if (userNameOwner is not null &&
            userNameOwner.Id != id)
        {
            throw new InvalidOperationException(
                "Username is already in use.");
        }

        var emailOwner =
            await repository.GetByEmailAsync(
                normalizedEmail,
                cancellationToken);

        if (emailOwner is not null &&
            emailOwner.Id != id)
        {
            throw new InvalidOperationException(
                "Email is already in use.");
        }

        user.UserName = normalizedUserName;
        user.Email = normalizedEmail;
        user.Role = request.Role;
        user.IsActive = request.IsActive;

        await repository.SaveChangesAsync(
            cancellationToken);

        return Map(user);
    }

    public async Task<bool> DeleteAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var user =
            await repository.GetByIdAsync(
                id,
                cancellationToken);

        if (user is null)
        {
            return false;
        }

        await repository.DeleteAsync(
            user,
            cancellationToken);

        await repository.SaveChangesAsync(
            cancellationToken);

        return true;
    }

    private static UserDto Map(AppUser user)
    {
        return new UserDto(
            user.Id,
            user.UserName,
            user.Email,
            user.Role,
            user.IsActive,
            user.CreatedAtUtc);
    }

    private static void ValidateRole(string role)
    {
        if (role is not Roles.Admin and not Roles.User)
        {
            throw new InvalidOperationException(
                $"Unsupported role: {role}");
        }
    }
}
```

This service now contains the actual CRUD logic that was missing from the earlier draft.

---

# 11. Infrastructure: DbContext

Create:

```text
UserManagement.Infrastructure/Persistence/AppDbContext.cs
```

```csharp
using Microsoft.EntityFrameworkCore;
using UserManagement.Domain.Entities;

namespace UserManagement.Infrastructure.Persistence;

public sealed class AppDbContext(
    DbContextOptions<AppDbContext> options)
    : DbContext(options)
{
    public DbSet<AppUser> Users =>
        Set<AppUser>();

    protected override void OnModelCreating(
        ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<AppUser>(entity =>
        {
            entity.ToTable("users");

            entity.HasKey(x => x.Id);

            entity.Property(x => x.Id)
                .ValueGeneratedNever();

            entity.Property(x => x.UserName)
                .HasMaxLength(100)
                .IsRequired();

            entity.HasIndex(x => x.UserName)
                .IsUnique();

            entity.Property(x => x.Email)
                .HasMaxLength(200)
                .IsRequired();

            entity.HasIndex(x => x.Email)
                .IsUnique();

            entity.Property(x => x.PasswordHash)
                .IsRequired();

            entity.Property(x => x.Role)
                .HasMaxLength(20)
                .IsRequired();

            entity.Property(x => x.IsActive)
                .IsRequired();

            entity.Property(x => x.CreatedAtUtc)
                .IsRequired();
        });
    }
}
```

---

# 12. Repository Implementation

Create:

```text
UserManagement.Infrastructure/Repositories/UserRepository.cs
```

```csharp
using Microsoft.EntityFrameworkCore;
using UserManagement.Application.Interfaces;
using UserManagement.Domain.Entities;
using UserManagement.Infrastructure.Persistence;

namespace UserManagement.Infrastructure.Repositories;

public sealed class UserRepository(
    AppDbContext db)
    : IUserRepository
{
    public async Task<IReadOnlyList<AppUser>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        return await db.Users
            .AsNoTracking()
            .OrderBy(x => x.UserName)
            .ToListAsync(cancellationToken);
    }

    public Task<AppUser?> GetByIdAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        return db.Users
            .FirstOrDefaultAsync(
                x => x.Id == id,
                cancellationToken);
    }

    public Task<AppUser?> GetByUserNameAsync(
        string userName,
        CancellationToken cancellationToken = default)
    {
        return db.Users
            .FirstOrDefaultAsync(
                x => x.UserName == userName,
                cancellationToken);
    }

    public Task<AppUser?> GetByEmailAsync(
        string email,
        CancellationToken cancellationToken = default)
    {
        return db.Users
            .FirstOrDefaultAsync(
                x => x.Email == email,
                cancellationToken);
    }

    public async Task AddAsync(
        AppUser user,
        CancellationToken cancellationToken = default)
    {
        await db.Users.AddAsync(
            user,
            cancellationToken);
    }

    public Task DeleteAsync(
        AppUser user,
        CancellationToken cancellationToken = default)
    {
        db.Users.Remove(user);

        return Task.CompletedTask;
    }

    public Task SaveChangesAsync(
        CancellationToken cancellationToken = default)
    {
        return db.SaveChangesAsync(
            cancellationToken);
    }
}
```

---

# 13. Password Hashing

For this tutorial we can use PBKDF2 with a random salt.

Create:

```text
UserManagement.Infrastructure/Security/PasswordHasher.cs
```

```csharp
using System.Security.Cryptography;
using UserManagement.Application.Interfaces;

namespace UserManagement.Infrastructure.Security;

public sealed class PasswordHasher
    : IPasswordHasher
{
    private const int SaltSize = 16;
    private const int KeySize = 32;
    private const int Iterations = 100_000;

    public string Hash(string password)
    {
        var salt =
            RandomNumberGenerator.GetBytes(SaltSize);

        var hash =
            Rfc2898DeriveBytes.Pbkdf2(
                password,
                salt,
                Iterations,
                HashAlgorithmName.SHA256,
                KeySize);

        return string.Join(
            ".",
            Convert.ToBase64String(salt),
            Convert.ToBase64String(hash));
    }

    public bool Verify(
        string password,
        string passwordHash)
    {
        var parts =
            passwordHash.Split('.');

        if (parts.Length != 2)
        {
            return false;
        }

        byte[] salt;
        byte[] expectedHash;

        try
        {
            salt =
                Convert.FromBase64String(parts[0]);

            expectedHash =
                Convert.FromBase64String(parts[1]);
        }
        catch (FormatException)
        {
            return false;
        }

        var actualHash =
            Rfc2898DeriveBytes.Pbkdf2(
                password,
                salt,
                Iterations,
                HashAlgorithmName.SHA256,
                KeySize);

        return CryptographicOperations
            .FixedTimeEquals(
                actualHash,
                expectedHash);
    }
}
```

This is adequate for a learning project. For a production identity system, use a mature identity framework such as ASP.NET Core Identity and a complete credential-management strategy.

---

# 14. JWT Options

Create:

```text
UserManagement.Infrastructure/Security/JwtOptions.cs
```

```csharp
namespace UserManagement.Infrastructure.Security;

public sealed class JwtOptions
{
    public const string SectionName = "Jwt";

    public string Key { get; set; } = string.Empty;

    public string Issuer { get; set; } = string.Empty;

    public string Audience { get; set; } = string.Empty;

    public int ExpiresMinutes { get; set; }
}
```

---

# 15. JWT Token Service

Create:

```text
UserManagement.Infrastructure/Security/JwtTokenService.cs
```

```csharp
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using UserManagement.Application.Interfaces;
using UserManagement.Domain.Entities;

namespace UserManagement.Infrastructure.Security;

public sealed class JwtTokenService(
    IOptions<JwtOptions> options)
    : IJwtTokenService
{
    private readonly JwtOptions jwt = options.Value;

    public string CreateToken(AppUser user)
    {
        var keyBytes =
            Encoding.UTF8.GetBytes(jwt.Key);

        var securityKey =
            new SymmetricSecurityKey(keyBytes);

        var credentials =
            new SigningCredentials(
                securityKey,
                SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(
                JwtRegisteredClaimNames.Sub,
                user.Id.ToString()),

            new Claim(
                ClaimTypes.Name,
                user.UserName),

            new Claim(
                ClaimTypes.Role,
                user.Role)
        };

        var token = new JwtSecurityToken(
            issuer: jwt.Issuer,
            audience: jwt.Audience,
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: DateTime.UtcNow.AddMinutes(
                jwt.ExpiresMinutes),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler()
            .WriteToken(token);
    }
}
```

---

# 16. Database Seeder

A common problem in tutorials is that login cannot actually be tested because there is no initial user.

We fix that here.

Create:

```text
UserManagement.Infrastructure/Persistence/DatabaseSeeder.cs
```

```csharp
using Microsoft.EntityFrameworkCore;
using UserManagement.Application.Interfaces;
using UserManagement.Domain.Constants;
using UserManagement.Domain.Entities;

namespace UserManagement.Infrastructure.Persistence;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(
        AppDbContext db,
        IPasswordHasher passwordHasher,
        CancellationToken cancellationToken = default)
    {
        if (await db.Users.AnyAsync(cancellationToken))
        {
            return;
        }

        var admin = new AppUser
        {
            Id = Guid.NewGuid(),
            UserName = "admin",
            Email = "admin@example.com",
            PasswordHash =
                passwordHasher.Hash("Admin123!"),
            Role = Roles.Admin,
            IsActive = true,
            CreatedAtUtc = DateTime.UtcNow
        };

        db.Users.Add(admin);

        await db.SaveChangesAsync(
            cancellationToken);
    }
}
```

The seeded development credentials are:

```text
Username: admin
Password: Admin123!
Role: Admin
```

**Do not use these credentials in a real application.**

---

# 17. appsettings.json

Create:

```text
UserManagement.Api/appsettings.json
```

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=UserManagementDb;Username=postgres;Password=YOUR_POSTGRES_PASSWORD"
  },

  "Jwt": {
    "Key": "CHANGE_THIS_TO_A_LONG_RANDOM_DEVELOPMENT_ONLY_SECRET_KEY_123456789",
    "Issuer": "UserManagement.Api",
    "Audience": "UserManagement.Angular",
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
```

Never commit real credentials or production JWT signing keys.

---

# 18. Program.cs — Complete Backend Startup

This is the most important file in the backend because it connects all layers.

Create/update:

```text
UserManagement.Api/Program.cs
```

```csharp
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using UserManagement.Application.Interfaces;
using UserManagement.Application.Services;
using UserManagement.Infrastructure.Persistence;
using UserManagement.Infrastructure.Repositories;
using UserManagement.Infrastructure.Security;

var builder = WebApplication.CreateBuilder(args);

var configuration =
    builder.Configuration;

// ----------------------------------------------------
// Controllers
// ----------------------------------------------------

builder.Services.AddControllers();

// ----------------------------------------------------
// Database
// ----------------------------------------------------

builder.Services.AddDbContext<AppDbContext>(
    options =>
    {
        options.UseNpgsql(
            configuration.GetConnectionString(
                "DefaultConnection"));
    });

// ----------------------------------------------------
// Application / Infrastructure DI
// ----------------------------------------------------

builder.Services.AddScoped<
    IUserRepository,
    UserRepository>();

builder.Services.AddScoped<
    IUserService,
    UserService>();

builder.Services.AddScoped<
    IPasswordHasher,
    PasswordHasher>();

builder.Services.AddScoped<
    IJwtTokenService,
    JwtTokenService>();

// ----------------------------------------------------
// JWT options
// ----------------------------------------------------

builder.Services.Configure<JwtOptions>(
    configuration.GetSection(
        JwtOptions.SectionName));

var jwt =
    configuration.GetSection(
        JwtOptions.SectionName);

var jwtKey =
    jwt["Key"]
    ?? throw new InvalidOperationException(
        "Jwt:Key is missing.");

var jwtIssuer =
    jwt["Issuer"]
    ?? throw new InvalidOperationException(
        "Jwt:Issuer is missing.");

var jwtAudience =
    jwt["Audience"]
    ?? throw new InvalidOperationException(
        "Jwt:Audience is missing.");

if (Encoding.UTF8.GetByteCount(jwtKey) < 32)
{
    throw new InvalidOperationException(
        "Jwt:Key must be at least 32 bytes.");
}

// ----------------------------------------------------
// Authentication
// ----------------------------------------------------

builder.Services
    .AddAuthentication(
        JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters =
            new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = jwtIssuer,

                ValidateAudience = true,
                ValidAudience = jwtAudience,

                ValidateLifetime = true,

                ValidateIssuerSigningKey = true,

                IssuerSigningKey =
                    new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(
                            jwtKey)),

                RoleClaimType =
                    ClaimTypes.Role,

                NameClaimType =
                    ClaimTypes.Name,

                ClockSkew =
                    TimeSpan.FromMinutes(1)
            };
    });

builder.Services.AddAuthorization();

// ----------------------------------------------------
// CORS
// ----------------------------------------------------

builder.Services.AddCors(options =>
{
    options.AddPolicy(
        "frontend",
        policy =>
        {
            policy
                .WithOrigins(
                    "http://localhost:4200")
                .AllowAnyHeader()
                .AllowAnyMethod();
        });
});

// ----------------------------------------------------
// Swagger / OpenAPI
// ----------------------------------------------------
//
// In .NET 9+ Swagger tooling is not included in the
// default Web API template. We explicitly add
// Swashbuckle.AspNetCore when we want Swagger UI.
//
// ----------------------------------------------------

builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc(
        "v1",
        new()
        {
            Title = "User Management API",
            Version = "v1"
        });

    options.AddSecurityDefinition(
        "bearer",
        new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            Description =
                "Enter the JWT access token."
        });

    options.AddSecurityRequirement(
        document =>
            new OpenApiSecurityRequirement
            {
                [
                    new OpenApiSecuritySchemeReference(
                        "bearer",
                        document)
                ] = []
            });
});

var app = builder.Build();

// ----------------------------------------------------
// Database migration + development seed
// ----------------------------------------------------

using (var scope =
       app.Services.CreateScope())
{
    var services = scope.ServiceProvider;

    var db =
        services.GetRequiredService<
            AppDbContext>();

    await db.Database.MigrateAsync();

    var passwordHasher =
        services.GetRequiredService<
            IPasswordHasher>();

    await DatabaseSeeder.SeedAsync(
        db,
        passwordHasher);
}

// ----------------------------------------------------
// Middleware
// ----------------------------------------------------

app.UseHttpsRedirection();

app.UseCors("frontend");

app.UseAuthentication();

app.UseAuthorization();

// ----------------------------------------------------
// Swagger
// ----------------------------------------------------

app.UseSwagger();

app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint(
        "/swagger/v1/swagger.json",
        "User Management API v1");
});

// ----------------------------------------------------
// Controllers
// ----------------------------------------------------

app.MapControllers();

app.Run();
```

### Why this Swagger configuration matters

There are two separate concepts:

1. ASP.NET Core has built-in OpenAPI support.
2. Swagger UI is an interactive UI provided by tooling such as Swashbuckle.

The current ASP.NET Core documentation explains that .NET 9+ uses built-in OpenAPI support by default, while Swashbuckle can still be added manually when you want Swagger tooling and the interactive UI. citeturn844149search3turn844149search8

For this tutorial, we intentionally choose Swashbuckle because we want the classic `/swagger` UI and the JWT **Authorize** button.

Also note that Swashbuckle 10.x uses the updated `Microsoft.OpenApi` namespace and API shape, so this guide does **not** use the older `Microsoft.OpenApi.Models` examples found in many older tutorials. The official Swashbuckle documentation shows the v10-style bearer configuration using `OpenApiSecuritySchemeReference`. citeturn925843search0turn925843search3

---

# 19. AuthController

Create:

```text
UserManagement.Api/Controllers/AuthController.cs
```

```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserManagement.Application.DTOs.Auth;
using UserManagement.Application.DTOs.Users;
using UserManagement.Application.Interfaces;

namespace UserManagement.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController(
    IUserRepository users,
    IPasswordHasher passwordHasher,
    IJwtTokenService tokenService)
    : ControllerBase
{
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<LoginResponse>> Login(
        LoginRequest request,
        CancellationToken cancellationToken)
    {
        var user =
            await users.GetByUserNameAsync(
                request.UserName.Trim(),
                cancellationToken);

        if (user is null ||
            !user.IsActive ||
            !passwordHasher.Verify(
                request.Password,
                user.PasswordHash))
        {
            return Unauthorized();
        }

        var token =
            tokenService.CreateToken(user);

        var dto = new UserDto(
            user.Id,
            user.UserName,
            user.Email,
            user.Role,
            user.IsActive,
            user.CreatedAtUtc);

        return Ok(
            new LoginResponse(
                token,
                dto));
    }
}
```

---

# 20. UsersController

Create:

```text
UserManagement.Api/Controllers/UsersController.cs
```

```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserManagement.Application.DTOs.Users;
using UserManagement.Application.Interfaces;
using UserManagement.Domain.Constants;

namespace UserManagement.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class UsersController(
    IUserService userService)
    : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<
        IReadOnlyList<UserDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var users =
            await userService.GetAllAsync(
                cancellationToken);

        return Ok(users);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<UserDto>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var user =
            await userService.GetByIdAsync(
                id,
                cancellationToken);

        if (user is null)
        {
            return NotFound();
        }

        return Ok(user);
    }

    [HttpPost]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<UserDto>> Create(
        CreateUserRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var created =
                await userService.CreateAsync(
                    request,
                    cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new { id = created.Id },
                created);
        }
        catch (InvalidOperationException exception)
        {
            return Conflict(
                new
                {
                    message =
                        exception.Message
                });
        }
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<UserDto>> Update(
        Guid id,
        UpdateUserRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var updated =
                await userService.UpdateAsync(
                    id,
                    request,
                    cancellationToken);

            if (updated is null)
            {
                return NotFound();
            }

            return Ok(updated);
        }
        catch (InvalidOperationException exception)
        {
            return Conflict(
                new
                {
                    message =
                        exception.Message
                });
        }
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Delete(
        Guid id,
        CancellationToken cancellationToken)
    {
        var deleted =
            await userService.DeleteAsync(
                id,
                cancellationToken);

        return deleted
            ? NoContent()
            : NotFound();
    }
}
```

This gives us:

```text
GET    /api/users
GET    /api/users/{id}
POST   /api/users
PUT    /api/users/{id}
DELETE /api/users/{id}
POST   /api/auth/login
```

---

# 21. EF Core Migrations

Install the EF CLI:

```bash
dotnet tool install --global dotnet-ef --version 10.0.12
```

If it already exists:

```bash
dotnet tool update --global dotnet-ef --version 10.0.12
```

Create the initial migration:

```bash
dotnet ef migrations add InitialCreate \
  --project UserManagement.Infrastructure \
  --startup-project UserManagement.Api
```

Apply it:

```bash
dotnet ef database update \
  --project UserManagement.Infrastructure \
  --startup-project UserManagement.Api
```

The sequence is:

```text
Entity
  ↓
EF Model
  ↓
Migration
  ↓
PostgreSQL schema
```

---

# 22. PostgreSQL

Create a local PostgreSQL database named:

```text
UserManagementDb
```

Or create it through `psql`:

```sql
CREATE DATABASE "UserManagementDb";
```

Update the connection string in `appsettings.json`.

Test connectivity:

```bash
dotnet ef database update \
  --project UserManagement.Infrastructure \
  --startup-project UserManagement.Api
```

When the application starts, `Database.MigrateAsync()` also ensures pending migrations are applied.

For a production deployment, migrations should normally be managed deliberately by the deployment process rather than automatically on every application startup.

---

# 23. Run the API

Start:

```bash
dotnet run --project UserManagement.Api
```

The API will print its local HTTPS URL.

Swagger will be available at:

```text
/swagger
```

For example:

```text
https://localhost:7000/swagger
```

Use the actual port printed by your application.

---

# 24. Test JWT Authentication in Swagger

The complete testing flow is:

### 1. Login

Call:

```text
POST /api/auth/login
```

Use:

```json
{
  "userName": "admin",
  "password": "Admin123!"
}
```

You should receive:

```json
{
  "accessToken": "eyJ...",
  "user": {
    "id": "...",
    "userName": "admin",
    "email": "admin@example.com",
    "role": "Admin",
    "isActive": true,
    "createdAtUtc": "..."
  }
}
```

### 2. Copy the access token

Copy only the token string.

### 3. Click Swagger's Authorize button

Enter:

```text
Bearer eyJ...
```

or, depending on Swagger UI presentation, enter the token value when the bearer scheme is selected.

### 4. Test GET

Call:

```text
GET /api/users
```

### 5. Test Admin-only endpoints

Call:

```text
POST /api/users
PUT /api/users/{id}
DELETE /api/users/{id}
```

Because the token contains the `Admin` role, these should be allowed.

---

# 25. 401 vs 403

## 401

The request is not successfully authenticated.

Typical causes:

- Missing token
- Invalid token
- Expired token
- Invalid signing key

## 403

The request is authenticated but the authenticated user does not have the required role or policy.

For example:

```text
User role = User
Endpoint requires = Admin
Result = 403
```

---

# 26. Angular 22 Project

Check your Node version:

```bash
node --version
```

Install the Angular CLI:

```bash
npm install -g @angular/cli
```

Create the application:

```bash
ng new user-management-ui --standalone --routing --style css
cd user-management-ui
```

Use Angular's standalone application model.

Run it:

```bash
ng serve
```

Open:

```text
http://localhost:4200
```

Angular 22 is currently supported and its compatibility requirements should be checked from the official Angular version table. citeturn844149search0

---

# 27. Add Tailwind CSS v4

This project uses Tailwind CSS v4.

Angular's official documentation provides two valid setup paths:

- Automated: `ng add tailwindcss`
- Manual: install `tailwindcss`, `@tailwindcss/postcss`, and `postcss`, configure PostCSS, then import Tailwind in the global stylesheet. citeturn844149search1

For a tutorial where the configuration is explicit, use the manual setup.

## 27.1 Install packages

From the Angular project root:

```bash
npm install tailwindcss @tailwindcss/postcss postcss
```

This matches the current Tailwind/Angular PostCSS setup. citeturn744190search0turn844149search1

## 27.2 Create `.postcssrc.json`

Create this file in the Angular project root:

```text
user-management-ui/.postcssrc.json
```

```json
{
  "plugins": {
    "@tailwindcss/postcss": {}
  }
}
```

Angular's official Tailwind guide documents this exact PostCSS plugin configuration. citeturn844149search1

## 27.3 Import Tailwind

Open:

```text
src/styles.css
```

and use:

```css
@import "tailwindcss";

html,
body {
  margin: 0;
  min-height: 100%;
}
```

Tailwind's v4 setup uses a CSS `@import` instead of the old v3 `@tailwind base; @tailwind components; @tailwind utilities;` directives. citeturn744190search0turn844149search1

## 27.4 Test Tailwind

Temporarily put this in a component:

```html
<div class="rounded-xl bg-slate-900 p-6 text-white">
  Tailwind CSS v4 is working.
</div>
```

Start Angular:

```bash
ng serve
```

---

# 28. Environment Configuration

Generate the environment files first if they are not present in the project:

```bash
ng generate environments
```

Then create/update:

```text
src/environments/environment.ts
```

```ts
export const environment = {
  production: true,
  apiUrl: 'https://localhost:7000/api'
};
```

For development:

```text
src/environments/environment.development.ts
```

```ts
export const environment = {
  production: false,
  apiUrl: 'https://localhost:7000/api'
};
```

Use the actual port printed by ASP.NET Core.

Angular's generated project configuration may already include environment replacement support. Keep the generated build configuration and verify that the development build points to the development environment file.

---

# 29. Angular Models

## 29.1 auth.models.ts

Create:

```text
src/app/core/models/auth.models.ts
```

```ts
import { User } from './user.models';

export interface LoginRequest {
  userName: string;
  password: string;
}

export interface LoginResponse {
  accessToken: string;
  user: User;
}
```

## 29.2 user.models.ts

Create:

```text
src/app/core/models/user.models.ts
```

```ts
export type UserRole = 'Admin' | 'User';

export interface User {
  id: string;
  userName: string;
  email: string;
  role: UserRole;
  isActive: boolean;
  createdAtUtc: string;
}

export interface CreateUserRequest {
  userName: string;
  email: string;
  password: string;
  role: UserRole;
}

export interface UpdateUserRequest {
  userName: string;
  email: string;
  role: UserRole;
  isActive: boolean;
}
```

---

# 30. Angular AuthService

Create:

```text
src/app/core/services/auth.service.ts
```

```ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  LoginRequest,
  LoginResponse
} from '../models/auth.models';
import { User } from '../models/user.models';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly http = inject(HttpClient);

  private readonly tokenKey =
    'access_token';

  private readonly userKey =
    'current_user';

  login(request: LoginRequest) {
    return this.http
      .post<LoginResponse>(
        `${environment.apiUrl}/auth/login`,
        request
      )
      .pipe(
        tap(response => {
          localStorage.setItem(
            this.tokenKey,
            response.accessToken
          );

          localStorage.setItem(
            this.userKey,
            JSON.stringify(response.user)
          );
        })
      );
  }

  logout(): void {
    localStorage.removeItem(
      this.tokenKey
    );

    localStorage.removeItem(
      this.userKey
    );
  }

  get token(): string | null {
    return localStorage.getItem(
      this.tokenKey
    );
  }

  get currentUser(): User | null {
    const raw =
      localStorage.getItem(
        this.userKey
      );

    if (!raw) {
      return null;
    }

    try {
      return JSON.parse(raw) as User;
    } catch {
      return null;
    }
  }

  isLoggedIn(): boolean {
    return !!this.token;
  }
}
```

For a production application, review whether browser storage is appropriate for your threat model. HttpOnly secure cookies can be preferable in some architectures.

---

# 31. Angular UserService

Create:

```text
src/app/core/services/user.service.ts
```

```ts
import {
  Injectable,
  inject
} from '@angular/core';

import {
  HttpClient
} from '@angular/common/http';

import { environment } from '../../../environments/environment';

import {
  CreateUserRequest,
  UpdateUserRequest,
  User
} from '../models/user.models';

@Injectable({
  providedIn: 'root'
})
export class UserService {
  private readonly http =
    inject(HttpClient);

  private readonly url =
    `${environment.apiUrl}/users`;

  getAll() {
    return this.http.get<User[]>(
      this.url
    );
  }

  getById(id: string) {
    return this.http.get<User>(
      `${this.url}/${id}`
    );
  }

  create(
    request: CreateUserRequest
  ) {
    return this.http.post<User>(
      this.url,
      request
    );
  }

  update(
    id: string,
    request: UpdateUserRequest
  ) {
    return this.http.put<User>(
      `${this.url}/${id}`,
      request
    );
  }

  delete(id: string) {
    return this.http.delete<void>(
      `${this.url}/${id}`
    );
  }
}
```

---

# 32. Angular Functional Interceptor

Create:

```text
src/app/core/interceptors/auth.interceptor.ts
```

```ts
import {
  HttpInterceptorFn
} from '@angular/common/http';

import { inject } from '@angular/core';

import {
  AuthService
} from '../services/auth.service';

export const authInterceptor:
  HttpInterceptorFn =
  (req, next) => {

    const authService =
      inject(AuthService);

    const token =
      authService.token;

    if (!token) {
      return next(req);
    }

    const authenticatedRequest =
      req.clone({
        setHeaders: {
          Authorization:
            `Bearer ${token}`
        }
      });

    return next(
      authenticatedRequest
    );
  };
```

The interceptor does not need to be manually called.

Once registered with `provideHttpClient`, it will run for outgoing HTTP requests.

---

# 33. Angular Auth Guard

Create:

```text
src/app/core/guards/auth.guard.ts
```

```ts
import {
  CanActivateFn,
  Router
} from '@angular/router';

import { inject } from '@angular/core';

import {
  AuthService
} from '../services/auth.service';

export const authGuard:
  CanActivateFn = () => {

    const auth =
      inject(AuthService);

    const router =
      inject(Router);

    return auth.isLoggedIn()
      ? true
      : router.createUrlTree([
          '/login'
        ]);
  };
```

This protects the frontend route.

Remember:

> A frontend guard is a UX/navigation feature, not the security boundary.

The backend remains responsible for actual authorization.

---

# 34. Angular Application Configuration

Open:

```text
src/app/app.config.ts
```

Use:

```ts
import {
  ApplicationConfig
} from '@angular/core';

import {
  provideRouter
} from '@angular/router';

import {
  provideHttpClient,
  withInterceptors
} from '@angular/common/http';

import {
  routes
} from './app.routes';

import {
  authInterceptor
} from './core/interceptors/auth.interceptor';

export const appConfig:
  ApplicationConfig = {
    providers: [
      provideRouter(routes),

      provideHttpClient(
        withInterceptors([
          authInterceptor
        ])
      )
    ]
  };
```

---

# 35. Angular Routes

Create:

```text
src/app/app.routes.ts
```

```ts
import {
  Routes
} from '@angular/router';

import {
  authGuard
} from './core/guards/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () =>
      import(
        './pages/login/login.component'
      ).then(
        module =>
          module.LoginComponent
      )
  },

  {
    path: 'users',
    canActivate: [
      authGuard
    ],
    loadComponent: () =>
      import(
        './pages/users/users.component'
      ).then(
        module =>
          module.UsersComponent
      )
  },

  {
    path: '',
    pathMatch: 'full',
    redirectTo: 'users'
  },

  {
    path: '**',
    redirectTo: 'users'
  }
];
```

---

# 36. Login Component

Create:

```text
src/app/pages/login/login.component.ts
```

```ts
import {
  Component,
  inject
} from '@angular/core';

import {
  FormControl,
  FormGroup,
  ReactiveFormsModule,
  Validators
} from '@angular/forms';

import {
  Router
} from '@angular/router';

import {
  AuthService
} from '../../core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    ReactiveFormsModule
  ],
  templateUrl:
    './login.component.html'
})
export class LoginComponent {
  private readonly auth =
    inject(AuthService);

  private readonly router =
    inject(Router);

  readonly form =
    new FormGroup({
      userName:
        new FormControl(
          'admin',
          {
            nonNullable: true,
            validators: [
              Validators.required
            ]
          }
        ),

      password:
        new FormControl(
          'Admin123!',
          {
            nonNullable: true,
            validators: [
              Validators.required,
              Validators.minLength(8)
            ]
          }
        )
    });

  errorMessage = '';

  isSubmitting = false;

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.errorMessage = '';
    this.isSubmitting = true;

    this.auth
      .login(
        this.form.getRawValue()
      )
      .subscribe({
        next: () => {
          this.isSubmitting = false;

          this.router.navigate([
            '/users'
          ]);
        },

        error: error => {
          this.isSubmitting = false;

          this.errorMessage =
            error?.status === 401
              ? 'Invalid username or password.'
              : 'Login failed.';
        }
      });
  }
}
```

---

# 37. Login Template with Tailwind CSS v4

Create:

```text
src/app/pages/login/login.component.html
```

```html
<div
  class="min-h-screen bg-slate-950 px-4 py-12 text-white"
>
  <div
    class="mx-auto max-w-md"
  >
    <div
      class="rounded-2xl border border-slate-800 bg-slate-900 p-8 shadow-2xl"
    >
      <div class="mb-8">
        <h1
          class="text-3xl font-bold"
        >
          User Management
        </h1>

        <p
          class="mt-2 text-sm text-slate-400"
        >
          Sign in to continue.
        </p>
      </div>

      @if (errorMessage) {
        <div
          class="mb-5 rounded-lg border border-red-800 bg-red-950/50 p-3 text-sm text-red-200"
        >
          {{ errorMessage }}
        </div>
      }

      <form
        [formGroup]="form"
        (ngSubmit)="submit()"
        class="space-y-5"
      >
        <div>
          <label
            class="mb-2 block text-sm font-medium text-slate-300"
            for="userName"
          >
            Username
          </label>

          <input
            id="userName"
            type="text"
            formControlName="userName"
            class="w-full rounded-lg border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-blue-500"
          />
        </div>

        <div>
          <label
            class="mb-2 block text-sm font-medium text-slate-300"
            for="password"
          >
            Password
          </label>

          <input
            id="password"
            type="password"
            formControlName="password"
            class="w-full rounded-lg border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-blue-500"
          />
        </div>

        <button
          type="submit"
          [disabled]="isSubmitting"
          class="w-full rounded-lg bg-blue-600 px-4 py-3 font-semibold transition hover:bg-blue-500 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {{ isSubmitting ? 'Signing in...' : 'Sign in' }}
        </button>
      </form>

      <div
        class="mt-6 rounded-lg border border-slate-800 bg-slate-950 p-4 text-sm text-slate-400"
      >
        Development account:
        <div class="mt-2 font-mono text-slate-200">
          admin / Admin123!
        </div>
      </div>
    </div>
  </div>
</div>
```

---

# 38. Users Component

Create:

```text
src/app/pages/users/users.component.ts
```

```ts
import {
  Component,
  OnInit,
  inject,
  signal
} from '@angular/core';

import {
  FormControl,
  FormGroup,
  ReactiveFormsModule,
  Validators
} from '@angular/forms';

import {
  Router
} from '@angular/router';

import {
  AuthService
} from '../../core/services/auth.service';

import {
  UserService
} from '../../core/services/user.service';

import {
  User,
  UserRole
} from '../../core/models/user.models';

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [
    ReactiveFormsModule
  ],
  templateUrl:
    './users.component.html'
})
export class UsersComponent
  implements OnInit {

  private readonly userService =
    inject(UserService);

  private readonly auth =
    inject(AuthService);

  private readonly router =
    inject(Router);

  readonly users =
    signal<User[]>([]);

  readonly editingId =
    signal<string | null>(null);

  readonly isLoading =
    signal(false);

  readonly errorMessage =
    signal('');

  readonly isAdmin =
    this.auth.currentUser?.role ===
    'Admin';

  readonly form =
    new FormGroup({
      userName:
        new FormControl(
          '',
          {
            nonNullable: true,
            validators: [
              Validators.required,
              Validators.minLength(3)
            ]
          }
        ),

      email:
        new FormControl(
          '',
          {
            nonNullable: true,
            validators: [
              Validators.required,
              Validators.email
            ]
          }
        ),

      password:
        new FormControl(
          '',
          {
            nonNullable: true
          }
        ),

      role:
        new FormControl<UserRole>(
          'User',
          {
            nonNullable: true
          }
        ),

      isActive:
        new FormControl(
          true,
          {
            nonNullable: true
          }
        )
    });

  ngOnInit(): void {
    this.loadUsers();
  }

  loadUsers(): void {
    this.isLoading.set(true);
    this.errorMessage.set('');

    this.userService
      .getAll()
      .subscribe({
        next: users => {
          this.users.set(users);
          this.isLoading.set(false);
        },

        error: () => {
          this.errorMessage.set(
            'Could not load users.'
          );

          this.isLoading.set(false);
        }
      });
  }

  submit(): void {
    if (!this.isAdmin) {
      return;
    }

    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const id =
      this.editingId();

    const value =
      this.form.getRawValue();

    if (!id && !value.password) {
      this.errorMessage.set(
        'Password is required when creating a user.'
      );

      return;
    }

    this.errorMessage.set('');

    if (id) {
      this.userService
        .update(
          id,
          {
            userName: value.userName,
            email: value.email,
            role: value.role,
            isActive: value.isActive
          }
        )
        .subscribe({
          next: () => {
            this.resetForm();
            this.loadUsers();
          },

          error: error => {
            this.errorMessage.set(
              error?.error?.message ??
              'Update failed.'
            );
          }
        });

      return;
    }

    this.userService
      .create({
        userName: value.userName,
        email: value.email,
        password: value.password,
        role: value.role
      })
      .subscribe({
        next: () => {
          this.resetForm();
          this.loadUsers();
        },

        error: error => {
          this.errorMessage.set(
            error?.error?.message ??
            'Create failed.'
          );
        }
      });
  }

  edit(user: User): void {
    if (!this.isAdmin) {
      return;
    }

    this.editingId.set(user.id);

    this.form.patchValue({
      userName: user.userName,
      email: user.email,
      password: '',
      role: user.role,
      isActive: user.isActive
    });
  }

  delete(id: string): void {
    if (!this.isAdmin) {
      return;
    }

    const confirmed =
      window.confirm(
        'Delete this user?'
      );

    if (!confirmed) {
      return;
    }

    this.userService
      .delete(id)
      .subscribe({
        next: () => {
          this.loadUsers();
        },

        error: error => {
          this.errorMessage.set(
            error?.error?.message ??
            'Delete failed.'
          );
        }
      });
  }

  resetForm(): void {
    this.editingId.set(null);

    this.form.reset({
      userName: '',
      email: '',
      password: '',
      role: 'User',
      isActive: true
    });
  }

  logout(): void {
    this.auth.logout();

    this.router.navigate([
      '/login'
    ]);
  }
}
```

---

# 39. Users Template

Create:

```text
src/app/pages/users/users.component.html
```

```html
<div
  class="min-h-screen bg-slate-100 px-4 py-8 text-slate-900"
>
  <div class="mx-auto max-w-7xl">
    <header
      class="mb-8 flex flex-col gap-4 rounded-2xl bg-white p-6 shadow-sm sm:flex-row sm:items-center sm:justify-between"
    >
      <div>
        <h1
          class="text-3xl font-bold"
        >
          Users
        </h1>

        <p
          class="mt-1 text-sm text-slate-500"
        >
          User management dashboard
        </p>
      </div>

      <div
        class="flex items-center gap-3"
      >
        <span
          class="rounded-full bg-slate-100 px-3 py-1 text-sm"
        >
          {{ auth.currentUser?.role }}
        </span>

        <button
          type="button"
          (click)="logout()"
          class="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium hover:bg-slate-50"
        >
          Logout
        </button>
      </div>
    </header>

    @if (errorMessage()) {
      <div
        class="mb-6 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700"
      >
        {{ errorMessage() }}
      </div>
    }

    <div
      class="grid gap-6 lg:grid-cols-[380px_1fr]"
    >
      @if (isAdmin) {
        <section
          class="rounded-2xl bg-white p-6 shadow-sm"
        >
          <div
            class="mb-6 flex items-center justify-between"
          >
            <h2
              class="text-xl font-semibold"
            >
              {{ editingId()
                ? 'Edit user'
                : 'Create user' }}
            </h2>

            @if (editingId()) {
              <button
                type="button"
                (click)="resetForm()"
                class="text-sm text-slate-500 hover:text-slate-900"
              >
                Cancel
              </button>
            }
          </div>

          <form
            [formGroup]="form"
            (ngSubmit)="submit()"
            class="space-y-4"
          >
            <div>
              <label
                class="mb-2 block text-sm font-medium"
              >
                Username
              </label>

              <input
                type="text"
                formControlName="userName"
                class="w-full rounded-lg border border-slate-300 px-3 py-2 outline-none focus:border-blue-500"
              />
            </div>

            <div>
              <label
                class="mb-2 block text-sm font-medium"
              >
                Email
              </label>

              <input
                type="email"
                formControlName="email"
                class="w-full rounded-lg border border-slate-300 px-3 py-2 outline-none focus:border-blue-500"
              />
            </div>

            @if (!editingId()) {
              <div>
                <label
                  class="mb-2 block text-sm font-medium"
                >
                  Password
                </label>

                <input
                  type="password"
                  formControlName="password"
                  class="w-full rounded-lg border border-slate-300 px-3 py-2 outline-none focus:border-blue-500"
                />
              </div>
            }

            <div>
              <label
                class="mb-2 block text-sm font-medium"
              >
                Role
              </label>

              <select
                formControlName="role"
                class="w-full rounded-lg border border-slate-300 px-3 py-2 outline-none focus:border-blue-500"
              >
                <option value="User">
                  User
                </option>

                <option value="Admin">
                  Admin
                </option>
              </select>
            </div>

            @if (editingId()) {
              <label
                class="flex items-center gap-2 text-sm"
              >
                <input
                  type="checkbox"
                  formControlName="isActive"
                />
                Active
              </label>
            }

            <button
              type="submit"
              class="w-full rounded-lg bg-blue-600 px-4 py-3 font-semibold text-white hover:bg-blue-500"
            >
              {{ editingId()
                ? 'Update user'
                : 'Create user' }}
            </button>
          </form>
        </section>
      }

      <section
        class="overflow-hidden rounded-2xl bg-white shadow-sm"
      >
        <div
          class="border-b border-slate-200 p-6"
        >
          <div
            class="flex items-center justify-between"
          >
            <h2
              class="text-xl font-semibold"
            >
              User list
            </h2>

            <button
              type="button"
              (click)="loadUsers()"
              class="rounded-lg border border-slate-300 px-3 py-2 text-sm hover:bg-slate-50"
            >
              Refresh
            </button>
          </div>
        </div>

        @if (isLoading()) {
          <div
            class="p-10 text-center text-slate-500"
          >
            Loading...
          </div>
        } @else {
          <div class="overflow-x-auto">
            <table
              class="min-w-full text-left text-sm"
            >
              <thead
                class="bg-slate-50 text-slate-600"
              >
                <tr>
                  <th class="px-6 py-4">
                    Username
                  </th>

                  <th class="px-6 py-4">
                    Email
                  </th>

                  <th class="px-6 py-4">
                    Role
                  </th>

                  <th class="px-6 py-4">
                    Status
                  </th>

                  @if (isAdmin) {
                    <th class="px-6 py-4">
                      Actions
                    </th>
                  }
                </tr>
              </thead>

              <tbody
                class="divide-y divide-slate-100"
              >
                @for (
                  user of users();
                  track user.id
                ) {
                  <tr
                    class="hover:bg-slate-50"
                  >
                    <td
                      class="px-6 py-4 font-medium"
                    >
                      {{ user.userName }}
                    </td>

                    <td
                      class="px-6 py-4"
                    >
                      {{ user.email }}
                    </td>

                    <td
                      class="px-6 py-4"
                    >
                      <span
                        class="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-medium text-blue-700"
                      >
                        {{ user.role }}
                      </span>
                    </td>

                    <td
                      class="px-6 py-4"
                    >
                      <span
                        class="rounded-full px-2.5 py-1 text-xs font-medium"
                        [class.bg-emerald-50]="user.isActive"
                        [class.text-emerald-700]="user.isActive"
                        [class.bg-red-50]="!user.isActive"
                        [class.text-red-700]="!user.isActive"
                      >
                        {{
                          user.isActive
                            ? 'Active'
                            : 'Inactive'
                        }}
                      </span>
                    </td>

                    @if (isAdmin) {
                      <td
                        class="px-6 py-4"
                      >
                        <div
                          class="flex gap-2"
                        >
                          <button
                            type="button"
                            (click)="edit(user)"
                            class="rounded-md bg-slate-100 px-3 py-2 text-xs font-medium hover:bg-slate-200"
                          >
                            Edit
                          </button>

                          <button
                            type="button"
                            (click)="delete(user.id)"
                            class="rounded-md bg-red-50 px-3 py-2 text-xs font-medium text-red-700 hover:bg-red-100"
                          >
                            Delete
                          </button>
                        </div>
                      </td>
                    }
                  </tr>
                } @empty {
                  <tr>
                    <td
                      colspan="5"
                      class="px-6 py-10 text-center text-slate-500"
                    >
                      No users found.
                    </td>
                  </tr>
                }
              </tbody>
            </table>
          </div>
        }
      </section>
    </div>
  </div>
</div>
```

---

# 40. One Small Angular Improvement

The `UsersComponent` template above uses:

```html
{{ auth.currentUser?.role }}
```

Because `auth` is declared private in TypeScript, Angular template access would fail.

So expose it as a template-visible property.

Change:

```ts
private readonly auth =
  inject(AuthService);
```

to:

```ts
readonly auth =
  inject(AuthService);
```

The final declaration in `UsersComponent` should therefore be:

```ts
readonly auth =
  inject(AuthService);
```

This is exactly the kind of small compile-time issue that can be missed when code is written as separate fragments, so it is important to validate the complete application rather than individual snippets.

---

# 41. Build the Frontend

Install dependencies:

```bash
npm install
```

Run:

```bash
ng serve
```

Then open:

```text
http://localhost:4200
```

---

# 42. Full End-to-End Test

## Step 1 — PostgreSQL

Verify PostgreSQL is running.

## Step 2 — Backend

Start:

```bash
dotnet run --project UserManagement.Api
```

## Step 3 — Swagger

Open:

```text
https://localhost:<api-port>/swagger
```

## Step 4 — Login

Use:

```text
admin
Admin123!
```

## Step 5 — Swagger Authorization

Copy the JWT and authorize Swagger.

## Step 6 — GET Users

Verify:

```text
GET /api/users
```

returns the seeded admin user.

## Step 7 — Create User

Use:

```json
{
  "userName": "alice",
  "email": "alice@example.com",
  "password": "Alice123!",
  "role": "User"
}
```

## Step 8 — Verify the new user

Call:

```text
GET /api/users
```

## Step 9 — Start Angular

```bash
ng serve
```

## Step 10 — Login in Angular

Open:

```text
http://localhost:4200/login
```

Use:

```text
admin
Admin123!
```

## Step 11 — Verify interceptor

Open browser developer tools.

Inspect a request to:

```text
GET /api/users
```

The request should contain:

```text
Authorization: Bearer <JWT>
```

## Step 12 — Verify CRUD

From Angular:

- Create user
- Edit user
- Delete user
- Refresh list

---

# 43. Important CORS Detail

The Angular development server is normally:

```text
http://localhost:4200
```

The ASP.NET Core API is normally HTTPS on another local port.

Therefore the API must allow the Angular origin:

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy(
        "frontend",
        policy =>
        {
            policy
                .WithOrigins(
                    "http://localhost:4200")
                .AllowAnyHeader()
                .AllowAnyMethod();
        });
});
```

And:

```csharp
app.UseCors("frontend");
```

The middleware needs to execute before the request reaches the controllers.

---

# 44. Why the Application Service Exists

A common architectural anti-pattern is:

```text
Controller
  |
  +-- EF Core query
  +-- validation
  +-- password hashing
  +-- business rule
  +-- mapping
```

The improved structure is:

```text
Controller
    |
    v
IUserService
    |
    v
IUserRepository
    |
    v
EF Core
```

That gives us:

- Smaller controllers
- Easier unit testing
- Clearer responsibilities
- Better separation of concerns
- Less coupling between HTTP and business logic

The complete `UserService.cs` is therefore an essential part of this tutorial, not optional sample code.

---

# 45. Why DTOs Matter

The entity is:

```text
AppUser
```

But the API exposes:

```text
UserDto
```

This prevents fields such as:

```text
PasswordHash
```

from leaking through an API response.

It also gives the frontend a stable contract.

---

# 46. Why Repository + Service?

A repository handles persistence concerns.

A service handles application/business concerns.

For example:

```text
UserRepository
    |
    +-- Query user
    +-- Add user
    +-- Delete user
    +-- Save changes
```

while:

```text
UserService
    |
    +-- Validate role
    +-- Check duplicate username
    +-- Check duplicate email
    +-- Hash password
    +-- Map entity to DTO
```

This separation is much easier to evolve.

---

# 47. Swagger vs OpenAPI

These words are often mixed together.

### OpenAPI

The specification describing the HTTP API.

### Swagger UI

The browser-based interface used to explore and test an OpenAPI document.

### Swashbuckle

A popular ASP.NET Core package for generating OpenAPI documentation and exposing Swagger UI.

Microsoft's documentation notes that OpenAPI became a first-class built-in capability in modern ASP.NET Core, while Swashbuckle remains an optional community package for Swagger tooling/UI. citeturn844149search3turn844149search8

For this tutorial:

```text
ASP.NET Core
   +
Swashbuckle.AspNetCore
   =
Swagger/OpenAPI generation + Swagger UI
```

---

# 48. Tailwind CSS v4: What Changed?

Older Tailwind tutorials often show:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

That is not the setup used by this guide.

Tailwind CSS v4 uses:

```css
@import "tailwindcss";
```

And with Angular/PostCSS:

```text
npm install tailwindcss @tailwindcss/postcss postcss
```

plus:

```json
{
  "plugins": {
    "@tailwindcss/postcss": {}
  }
}
```

This is the current setup documented by both Angular and Tailwind. citeturn844149search1turn744190search0

---

# 49. Recommended Production Improvements

This tutorial is complete as a learning project, but production software should go further.

Recommended improvements include:

- ASP.NET Core Identity
- Refresh-token strategy
- More robust credential management
- Centralized exception handling
- ProblemDetails responses
- Structured logging
- FluentValidation or equivalent validation strategy
- Automated unit tests
- Integration tests
- Pagination
- Filtering
- Sorting
- API versioning
- Rate limiting
- Audit logging
- Secret manager / environment variables
- Secure cookie-based authentication where appropriate
- Production database migration strategy
- Better authorization policies
- Docker
- CI/CD

The current sample deliberately remains compact so the architecture is understandable.

---

# 50. Final Architecture Diagram

```text
                         +--------------------+
                         |   Angular 22 UI    |
                         |   Tailwind CSS v4  |
                         +---------+----------+
                                   |
                                   | HTTPS + JWT
                                   v
                         +--------------------+
                         | ASP.NET Core 10    |
                         |       API          |
                         +---------+----------+
                                   |
                         +---------v----------+
                         |    Controllers     |
                         +---------+----------+
                                   |
                         +---------v----------+
                         |    Application     |
                         |                    |
                         | DTOs               |
                         | Services           |
                         | Interfaces         |
                         +---------+----------+
                                   |
                         +---------v----------+
                         |   Infrastructure   |
                         |                    |
                         | EF Core            |
                         | Repository         |
                         | JWT                |
                         | Password Hashing   |
                         +---------+----------+
                                   |
                         +---------v----------+
                         |    PostgreSQL      |
                         +--------------------+
```

---

# 51. Final Checklist

## Backend

- [x] .NET 10 solution
- [x] Domain project
- [x] Application project
- [x] Infrastructure project
- [x] API project
- [x] Entity
- [x] Roles
- [x] DTOs
- [x] Repository interface
- [x] Repository implementation
- [x] `UserService.cs`
- [x] Password hashing
- [x] JWT service
- [x] JWT validation
- [x] Controllers
- [x] PostgreSQL
- [x] EF Core
- [x] EF migrations
- [x] Database seed
- [x] CORS
- [x] Swagger
- [x] Swagger JWT authorization
- [x] Complete API startup

## Frontend

- [x] Angular 22
- [x] Standalone architecture
- [x] Models
- [x] AuthService
- [x] UserService
- [x] JWT interceptor
- [x] Auth guard
- [x] Routing
- [x] Login page
- [x] Users page
- [x] Reactive Forms
- [x] CRUD
- [x] Role-based UI
- [x] Loading state
- [x] Error state
- [x] Tailwind CSS v4
- [x] PostCSS configuration
- [x] Global Tailwind import
- [x] Environment configuration

---

# 52. Final Verification Notes

This document was reviewed against the uploaded source guide and expanded specifically where that guide was incomplete.

The original source already established the intended architecture:

```text
Domain
Application
Infrastructure
API
```

and the intended end-to-end flow:

```text
Angular
  ->
JWT
  ->
ASP.NET Core
  ->
Application
  ->
Repository
  ->
EF Core
  ->
PostgreSQL
```

It also identified the original guide as a learning/practice guide rather than a production boilerplate. The missing implementation detail was primarily in the actual application service and in connecting all of the fragments into one internally consistent executable flow. fileciteturn1file7L396-L410 fileciteturn1file4L229-L241

The current version additionally verifies:

- .NET 10 is the active LTS line in September 2026. citeturn900177search0
- Angular 22 is actively supported. citeturn844149search0
- Tailwind's Angular/PostCSS v4 configuration uses `tailwindcss`, `@tailwindcss/postcss`, `postcss`, `.postcssrc.json`, and `@import "tailwindcss"`. citeturn844149search1turn744190search0
- Swashbuckle 10.2.3 is available for .NET 10. citeturn744190search1
- Swashbuckle 10.x uses the updated OpenAPI types and bearer security-reference configuration. citeturn925843search0turn925843search3
- EF Core 10.0.12 and the corresponding design package are available for .NET 10, and Npgsql EF Core 10.0.3 targets .NET 10. citeturn880267search5turn880267search2turn880267search7

---

# 53. Official References

- .NET support policy: https://dotnet.microsoft.com/en-us/platform/support/policy
- ASP.NET Core OpenAPI: https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/aspnetcore-openapi
- ASP.NET Core Swagger/OpenAPI: https://learn.microsoft.com/en-us/aspnet/core/tutorials/web-api-help-pages-using-swagger
- Angular version compatibility: https://angular.dev/reference/versions
- Angular + Tailwind: https://angular.dev/guide/tailwind
- Tailwind CSS PostCSS installation: https://tailwindcss.com/docs/installation/using-postcss
- Swashbuckle.AspNetCore: https://www.nuget.org/packages/Swashbuckle.AspNetCore
- Entity Framework Core: https://www.nuget.org/packages/Microsoft.EntityFrameworkCore
- Npgsql EF Core provider: https://www.nuget.org/packages/Npgsql.EntityFrameworkCore.PostgreSQL

---

## Conclusion

The important lesson is not memorizing every file.

It is understanding the responsibility boundaries:

```text
Angular
  -> calls API

Interceptor
  -> attaches JWT

API
  -> handles HTTP

Application
  -> implements use cases/business flow

Infrastructure
  -> handles technical details

EF Core
  -> maps objects to database operations

PostgreSQL
  -> stores the data
```

Once that mental model is clear, changing the entity from `User` to `Product`, `Equipment`, `Order`, `Employee`, or any other domain becomes largely a matter of changing the domain model, DTOs, service rules, repository queries, and UI while keeping the same architectural pipeline.
