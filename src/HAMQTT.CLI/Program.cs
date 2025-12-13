using System.Diagnostics;

// 1. Resolve path to the bundled script
// Since hamqtt.ps1 is copied to the output directory, it is in the BaseDirectory.
var toolRoot = AppDomain.CurrentDomain.BaseDirectory;
var scriptPath = Path.Combine(toolRoot, "hamqtt.ps1");

// 2. Validate environment
if (!File.Exists(scriptPath))
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine($"Error: Critical component missing. Could not locate: {scriptPath}");
    Console.ResetColor();
    return 1;
}

// 3. Construct arguments
var argsString = string.Join(" ", args.Select(a => $"\"{a}\""));
var psArgs = $"-NoProfile -ExecutionPolicy Bypass -File \"{scriptPath}\" {argsString}";

// 4. Prepare Process
var psi = new ProcessStartInfo
{
    FileName = "pwsh",
    Arguments = psArgs,
    UseShellExecute = false,
    CreateNoWindow = false
};

// 5. Execute
try
{
    var process = Process.Start(psi);
    if (process == null)
    {
        Console.Error.WriteLine("Failed to start PowerShell process.");
        return 1;
    }

    process.WaitForExit();
    return process.ExitCode;
}
catch (System.ComponentModel.Win32Exception)
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine("Error: 'pwsh' (PowerShell Core) is not found in your PATH.");
    Console.WriteLine("Please install PowerShell Core to use this tool.");
    Console.ResetColor();
    return 1;
}