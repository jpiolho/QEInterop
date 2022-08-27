# QEInterop
A proof of concept QuakeC library + C# program for Quake Enhanced that allows communication between QC and an external database

## Quick start
* Import 'interop.qc' into your progs.src

### Save how many times a player used 'kill'
```qc
void() ClientKill =
{
  Interop::SetKey(self.netname,".kill");
  Interop::DatabaseIncrement();
  
  // ...
}
```

### Show many times the player used 'kill'
* Based on previous example
```qc
void(float success, float value) ShowPlayerKillCount1 =
{
  if(success) {
    centerprint(self,"Seems like you've used 'kill' this many times: {}",ftos(value));
  }
}

// Call this to how the player how many times it used 'kill'
void() ShowPlayerKillCount = 
{
  Interop::SetKey(self.netname,".kill");
  Interop::DatabaseGet(ShowPlayerKillCount);
}
```

### Track if player is joining for the first time
```qc

void(float success, float value) HasClientConnectedBefore =
{
  if(success) {
    centerprint(self,"Welcome back!");
  } else {
    centerprint(self,"Seems like this is the first time you're joining this server");
  }
}

void() ClientConnect =
{
  Interop::SetKey(self.netname);
  Interop::DatabaseGet(HasClientConnectedBefore);
}
```

### Show current date and time
```qc
float date_day,date_month,date_year;

void(float hours, float minutes, float seconds) ShowCurrentTime2 =
{
  centerprint(self,"The current time is: {}-{}-{} {}:{}",ftos(date_day),ftos(date_month),ftos(date_year),ftos(hours),ftos(minutes),ftos(seconds));
  
  Interop::EndScope();
}

void(float day,float month,float year) ShowCurrentTime1 =
{
  // Save the date
  date_day = day;
  date_month = month;
  date_year = year;
  
  Interop::GetCurrentTime(ShowCurrentTime2,Interop::CurrentScope());
}

void() PutClientInServer =
{
  Interop::GetCurrentDate(ShowCurrentTime1,Interop::CreateScope());
  
  // ...
}
```

## How it works
So keep in mind that this is a proof of concept and it's quite "hacky" to say the least.

This works by taking over your backspace key...

Saving a config file...

and executing another config file.

---

Quake Enhanced includes the command `writeuserconfig` which lets you save your current binds and cvars.
Whenever QC wants to send a message to the external program, it writes the command to the `backspace` key bind and then
saves the config by using `writeuserconfig`.

The external program is then pooling the `kexengine.cfg` file for changes and reads the command that QC wrote into the `backspace` bind. 
(Why backspace? Because it's the first bind that gets written in the config.)

The command includes a packet ID to prevent executing the same command over and over again.

After the external program reads and executes the command from QC it needs to send some data back. To do this, it writes the response
as a bunch of cvars `temp1` through `temp5` into a separate config file: `interop.cfg`

In the meantime, QC has also been polling `interop.cfg` waiting for a response by doing `exec interop.cfg` and reading the cvar numbers.

Then it's just a matter of packaging everything up into a neat high level QC library. 

## Pros & Cons

### Pros
* Non-intrusive: Since the external program is only reading files and writing files, it does not inject or modify anything in the Quake process.
* Future proof: Should work on all previous and future versions, as long as `writeuserconfig`, `exec`, and `temp1-5` behaviour is not changed.

### Cons
* Transfer speed: Due to the method of using files it's not very fast in a programming sense.
It can take ~150ms to execute one command and get the response.
* Asynchronous: QuakeC is not asynchronous in nature, however to use this you need to program that way using callbacks and such.
So that makes it a bit more cumbersome and harder to program for.
* Only numeric values: Because QC can't read string cvars, there's no support for passing text.
* HDD usage: Due to reading and writing on files, it might wear off a little bit of your HDD.
