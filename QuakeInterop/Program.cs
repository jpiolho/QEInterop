using System.Linq;
using System.Text.Json;

namespace QuakeInterop
{
    internal class Program
    {
        const string Bind = "bind backspace \"";
        const string DatabaseFile = "database.json";

        private static Dictionary<string, float> _db = new Dictionary<string, float>();


        static async Task<float[]> HandleCommand(string[] command)
        {
            if (command[0] == "dbset")
            {
                if (float.TryParse(command[2], out var value))
                {
                    _db[command[1]] = value;
                    return new float[] { 1 };
                }

                return new float[] { 0 };
            }
            else if (command[0] == "dbget")
            {
                if(_db.TryGetValue(command[1],out var value))
                {
                    return new float[] { 1, value };
                }
            }
            else if (command[0] == "dbinc")
            {
                if (!float.TryParse(command[2], out var inc))
                    return new float[] { 0 };

                if (!_db.TryGetValue(command[1], out var value))
                    value = 0;

                value += inc;
                _db[command[1]] = value;
                return new float[] { value };
            }
            else if (command[0] == "dbdelete")
            {
                var success = _db.Remove(command[1]);

                return new float[] { success ? 1 : 0 };
            }
            else if (command[0] == "date")
            {
                var dt = DateTime.Now;
                return new float[] { dt.Day, dt.Month, dt.Year };
            }
            else if (command[0] == "time")
            {
                var dt = DateTime.Now;
                return new float[] { dt.Hour, dt.Minute, dt.Second };
            }

            return Array.Empty<float>();
        }

        static async Task Main(string[] args)
        {
            DateTime nextSaveDate = DateTime.Now.Add(TimeSpan.FromMinutes(5));
            int lastPacketId = -1;


            // Load existing database
            if (File.Exists(DatabaseFile))
                _db = JsonSerializer.Deserialize<Dictionary<string,float>>(await File.ReadAllTextAsync(DatabaseFile))!;

            var folder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),"Saved Games","Nightdive Studios","Quake");

            while(true)
            {
                // Read line from file
                string line;
                try
                {
                    using (var stream = new FileStream(Path.Combine(folder, "kexengine.cfg"), FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                    using (var reader = new StreamReader(stream, leaveOpen: true))
                    {
                        line = await reader.ReadLineAsync();
                    }
                }
                catch(Exception ex)
                {
                    await Task.Delay(50);
                    continue;
                }

                if(line.StartsWith(Bind))
                {
                    var contents = line.Substring(Bind.Length, line.Length - Bind.Length - 1);

                    var idx = contents.IndexOf("\\\"");

                    // Is there content?
                    if (idx >= 1)
                    {
                        var packetIdString = contents.Substring(0, idx);

                        if (int.TryParse(packetIdString, out var packetId))
                        {
                            if (packetId != lastPacketId)
                            {
                                var command = contents.Substring(idx + 2);

                                Console.WriteLine($"[{packetId}] {command}");

                                var response = await HandleCommand(command.Split("\\\""));

                                // Write response
                                var responseStr = $"seta temp1 {packetId}";
                                for(var i=0;i<response.Length;i++)
                                    responseStr += $";seta temp{i + 2} {response[i]}";

                                await File.WriteAllTextAsync(Path.Combine(folder, "interop.cfg"), responseStr);

                                lastPacketId = packetId;
                            }
                        }
                    }
                }

                if(DateTime.Now >= nextSaveDate)
                {
                    Console.Write("Saving database... ");
                    await File.WriteAllTextAsync(DatabaseFile, JsonSerializer.Serialize(_db));
                    nextSaveDate = DateTime.Now.AddMinutes(5);

                    Console.WriteLine("DONE");
                }

                await Task.Delay(50);
                
            }
            
        }
    }
}