using System;
using System.Collections.ObjectModel;
using System.Data;
using System.Reflection;
using System.Text;
using CG.MobileAPI.Data;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using Microsoft.OpenApi.Models;
using Serilog;
using Serilog.Sinks.MSSqlServer;
using Serilog.Sinks.MSSqlServer.Configuration;

var builder = WebApplication.CreateBuilder(new WebApplicationOptions
{
    Args = args,
    ContentRootPath = AppContext.BaseDirectory, // <-- fissa la root dove sta l'eseguibile
    WebRootPath = "wwwroot"
});

builder.Services.AddSwaggerGen(opts =>
{
    opts.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Il mio Web API",
        Version = "v1",
        Description = "API per gestire ...",
    });

    // Includi il file XML dei commenti
    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    opts.IncludeXmlComments(xmlPath);
    opts.EnableAnnotations();
});

// ————— Caricamento della configurazione da config.json —————
builder.Configuration
       .AddJsonFile(Path.Combine(Directory.GetCurrentDirectory(), "config.json"),
                    optional: false, reloadOnChange: true);

// ————— Configurazione di Serilog —————
var logConnStringTEST = builder.Configuration.GetConnectionString("LogDbTEST");
var logConnString = builder.Configuration.GetConnectionString("LogDb");

// 1) Preparo ColumnOptions
var columnOptions = new ColumnOptions();

// Rimuovo solo le colonne realmente assenti
columnOptions.Store.Remove(StandardColumn.Properties);
columnOptions.Store.Remove(StandardColumn.MessageTemplate);


// 2) Aggiungo i campi custom
columnOptions.AdditionalColumns = new Collection<SqlColumn>
{
    new SqlColumn {
        ColumnName = "LOG_CODSOC",
        DataType   = SqlDbType.VarChar,
        DataLength = 5,
        AllowNull  = true
    },
    new SqlColumn {
        ColumnName = "LOG_ORIGIN",
        DataType   = SqlDbType.VarChar,
        DataLength = 50,
        AllowNull  = true
    },
    new SqlColumn {
        ColumnName = "LOG_WS_CONTROLLER",
        DataType   = SqlDbType.VarChar,
        DataLength = 100,
        AllowNull  = true
    },
    new SqlColumn {
        ColumnName = "LOG_WS_ACTION",
        DataType   = SqlDbType.VarChar,
        DataLength = 100,
        AllowNull  = true
    },
    new SqlColumn {
        ColumnName = "LOG_USER",
        DataType   = SqlDbType.VarChar,
        DataLength = 50,
        AllowNull  = true
    }
};

bool verbose = builder.Configuration.GetValue<bool>("configuration:verboseLogs");
bool isTest = builder.Configuration.GetValue<bool>("configuration:isTest");
bool runDailyJob = builder.Configuration.GetValue<bool>("configuration:runDailyJob");

// 3) Build del logger con AutoCreateSqlTable = true
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .WriteTo.MSSqlServer(
        connectionString: isTest ? logConnStringTEST : logConnString,
        sinkOptions: new MSSqlServerSinkOptions
        {
            SchemaName = "dbo",
            TableName = "CGWS_LOGS",
            AutoCreateSqlTable = false    //  qui permetti a Serilog di creare lo schema corretto
        },
        columnOptions: columnOptions,
        restrictedToMinimumLevel: verbose ? Serilog.Events.LogEventLevel.Verbose : Serilog.Events.LogEventLevel.Warning
    )
    .CreateLogger();

// 4) Sostituisci il logger di default con Serilog
builder.Host.UseSerilog();

// ————— Registrazione dei servizi dell’app —————
builder.Services.AddControllers().AddJsonOptions(opts =>
{
    // Il client manda numeri e booleani nel loro tipo JSON: i modelli li accettano anche dove il campo è stringa
    // (e viceversa per numeri e bool).
    opts.JsonSerializerOptions.Converters.Add(new StringaFlessibileConverter());
    opts.JsonSerializerOptions.Converters.Add(new BoolFlessibileConverter());
    opts.JsonSerializerOptions.NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowReadingFromString;
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

//Per pagina MVC
builder.Services.AddControllersWithViews();  // se vuoi anche la pagina MVC (ti conviene)
builder.Services.AddHttpClient();

// Configura il tuo ConfigurationLoader
builder.Services.Configure<ConfigurationLoader>(
    builder.Configuration.GetSection("configuration")
);

// Servizi dell'app mobile (ex PHP mobile/server)
builder.Services.Configure<MobileSettings>(builder.Configuration.GetSection("mobile"));
builder.Services.PostConfigure<MobileSettings>(s => s.Diapason.IsTest = isTest);
builder.Services.AddSingleton(sp =>
{
    var conf = sp.GetRequiredService<IConfiguration>();
    return new MobileConnections
    {
        Db2 = isTest ? conf.GetConnectionString("DB2ConnectionTest") : conf.GetConnectionString("DB2ConnectionProd"),
        Db2Modula = isTest ? conf.GetConnectionString("DB2ConnectionTest") : conf.GetConnectionString("DB2ConnectionProd"),
        Db2Replica = conf.GetConnectionString("DB2ConnectionBCK") ?? "",
        PgCasagrande = isTest ? (conf.GetConnectionString("PostgreConnectionTEST") ?? "") : (conf.GetConnectionString("PostgreConnection") ?? ""),
        PgDb1 = conf.GetConnectionString("MobilePgDB1") ?? "",
        PgCasagrandeDev = conf.GetConnectionString("MobilePgCasagrandeDev") ?? ""
    };
});
builder.Services.AddSingleton<DiapasonSocket>();
builder.Services.AddSingleton<DiapasonExe>();
builder.Services.AddSingleton<StorageTool>();
builder.Services.AddSingleton<DisegniTool>();
builder.Services.AddSingleton<EmailTool>();

// Inietta MyDbContext
builder.Services.AddScoped<MyDbContext>(sp =>
{
    var cfg = sp.GetRequiredService<IOptions<ConfigurationLoader>>().Value;
    var conf = sp.GetRequiredService<IConfiguration>();

    var connT = conf.GetConnectionString("DB2ConnectionTest") ?? "";
    var connP = conf.GetConnectionString("DB2ConnectionProd") ?? "";
    var connB = conf.GetConnectionString("DB2ConnectionBCK") ?? "";
    var connG = conf.GetConnectionString("MySQLConfig") ?? "";
    var connGT = conf.GetConnectionString("MySQLConfigTEST") ?? "";
    var connPg = conf.GetConnectionString("PostgreConnection") ?? "";

    return new MyDbContext(connT, connP, connB, connG, connGT, connPg,
                           Options.Create(cfg), sp.GetRequiredService<MobileConnections>());
});

// CORS per Flutter Web
builder.Services.AddCors(opts =>
    opts.AddPolicy("AllowFlutterWeb", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader()
    )
);

// Kestrel
builder.WebHost.ConfigureKestrel(opts =>
    builder.Configuration.GetSection("Kestrel").Bind(opts)
);

// JWT Bearer
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opts =>
    {
        opts.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ClockSkew = TimeSpan.Zero,
            ValidIssuer = TokenTool.TokenIssuer,
            ValidAudience = TokenTool.TokenAudience,
            IssuerSigningKey = new SymmetricSecurityKey(
                                            Encoding.UTF8.GetBytes(
                                                TokenTool.CryptedKey))
        };

        opts.Events = new JwtBearerEvents
        {
            // EventSource (stream SSE) non può mandare l'header Authorization: per i soli endpoint di stream
            // il token è accettato anche in query string (?access_token=...).
            OnMessageReceived = context =>
            {
                var path = context.HttpContext.Request.Path;
                var token = context.Request.Query["access_token"].ToString();
                if (!string.IsNullOrEmpty(token) &&
                    (path.StartsWithSegments("/api/chat/ChatStream") || path.StartsWithSegments("/api/movimenti/MovimentiMagazzinoSSE")))
                {
                    context.Token = token;
                }
                return Task.CompletedTask;
            },
            OnAuthenticationFailed = context =>
            {
                if (context.Exception is SecurityTokenExpiredException expiredEx)
                {
                    context.NoResult();
                    // se vuoi puoi anche sovrascrivere lo status code:
                    context.Response.StatusCode = 401; // login timeout
                }
                return Task.CompletedTask;
            }
        };
    });
builder.Services.AddAuthorization();

// ————— Build dell’app e middleware pipeline —————
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseRouting();

app.UseCors("AllowFlutterWeb");

app.UseAuthentication();
app.UseAuthorization();

app.UseStaticFiles();
app.MapControllers();

app.Run();
