static var float interop_packetId = 1;
static var float interop_busy = FALSE;
static var string key1;
static var string key2;
static var string key3;
static var string key4;
static var float interop_scopeId = 0;
static var float interop_currentScope = -1;
static var float interop_endScope = FALSE;

#define INTEROP_SEPARATOR "\\\\\""

#ifndef INTEROP_DEBUG
#define INTEROP_DEBUG FALSE
#endif

#ifndef INTEROP_INBOX_CFG
#define INTEROP_INBOX_CFG "interop.cfg"
#endif

#define INTEROP_FIELD_SCOPE fly_sound
#define INTEROP_FIELD_STARTTIME rad_time

.void(optional float, optional float, optional float, optional float) interop_callback;

.string interop_key1;
.string interop_key2;
.string interop_key3;
.string interop_key4;

class Interop {
    static nonvirtual void() SkipThink;
    static nonvirtual void() StartWriteCommand;
    static nonvirtual void() EndWriteCommand;
    static nonvirtual float() HasReceivedPacket;
};

class InteropCommandBase : entity {
    virtual void() SkipThink = {
        nextthink = time + 0.05;
    };

    virtual string() GetName = { return ""; };
    virtual void() PacketReceived = {};
    virtual void() WriteCommand = {};

    virtual void() WriteKey = {
        localcmd(interop_key1);
        localcmd(interop_key2);
        localcmd(interop_key3);
        localcmd(interop_key4);
    };

    virtual void() think = {
        if(state) {
            if(!Interop::HasReceivedPacket())
                return SkipThink();

            ::interop_busy = FALSE;
            ::interop_packetId++;

            if(INTEROP_DEBUG) {
                dprint("< [");
                dprint(ftos(time - INTEROP_FIELD_STARTTIME));
                dprint("s] ");
                dprint(ftos(cvar("temp1")));
                dprint(" ");
                dprint(ftos(cvar("temp2")));
                dprint(" ");
                dprint(ftos(cvar("temp3")));
                dprint(" ");
                dprint(ftos(cvar("temp4")));
                dprint(" ");
                dprint(ftos(cvar("temp5")));
                dprint("\n");
            }

            if(::interop_endScope) {
                ::interop_currentScope = -1;
                ::interop_endScope = FALSE;
            }
            
            PacketReceived();

            remove(self);
            return;
        }
        else {
            // Is another command running?
            if(::interop_busy)
                return SkipThink();

            // Ensure it's in the current scope
            if(INTEROP_FIELD_SCOPE != -1 && ::interop_currentScope != -1 && ::interop_currentScope != INTEROP_FIELD_SCOPE) {
                return SkipThink();
            }

            state = TRUE;
            ::interop_busy = TRUE;
            ::interop_currentScope = INTEROP_FIELD_SCOPE;

            if(INTEROP_DEBUG) {
                dprint("> ");
                dprint(GetName());
                dprint("\n");
            }

            WriteCommand();

            SkipThink();
        }
    };

    void() InteropCommandBase = {
        nextthink = time;
        INTEROP_FIELD_STARTTIME = time;

        interop_key1 = ::key1;
        interop_key2 = ::key2;
        interop_key3 = ::key3;
        interop_key4 = ::key4;
    };
};

class InteropCommandBase_Callback1 : InteropCommandBase {
    virtual void() PacketReceived = {
        entity oself = ::self;
        if(interop_callback != __NULL__) {
            void(float) callback = interop_callback;
            ::self = ::self.owner;
            callback(cvar("temp2"));                
            ::self = oself;
        }
    };
};

class InteropCommandBase_Callback2 : InteropCommandBase {
    virtual void() PacketReceived = {
        entity oself = ::self;
        if(interop_callback != __NULL__) {
            void(float,float) callback = interop_callback;
            ::self = ::self.owner;
            callback(cvar("temp2"),cvar("temp3"));                
            ::self = oself;
        }
    };
};

class InteropCommandBase_Callback3 : InteropCommandBase {
    virtual void() PacketReceived = {
        entity oself = ::self;
        if(interop_callback != __NULL__) {
            void(float,float,float) callback = interop_callback;
            ::self = ::self.owner;
            callback(cvar("temp2"),cvar("temp3"),cvar("temp4"));                
            ::self = oself;
        }
    };
};

class InteropCommandBase_Callback4 : InteropCommandBase {
    virtual void() PacketReceived = {
        entity oself = ::self;
        if(interop_callback != __NULL__) {
            void(float,float,float,float) callback = interop_callback;
            ::self = ::self.owner;
            callback(cvar("temp2"),cvar("temp3"),cvar("temp4"),cvar("temp5"));                
            ::self = oself;
        }
    };
};




class Interop_DatabaseSet : InteropCommandBase_Callback1 {

    virtual string() GetName = { return "DatabaseGet"; };

    virtual void() WriteCommand = {
        Interop::StartWriteCommand();
        localcmd("dbset"INTEROP_SEPARATOR);
        WriteKey();
        localcmd(INTEROP_SEPARATOR);
        localcmd(ftos(volume));
        Interop::EndWriteCommand();
    };

};

class Interop_DatabaseGet : InteropCommandBase_Callback2 {
    virtual string() GetName = { return "DatabaseSet"; };

    virtual void() WriteCommand = {
        Interop::StartWriteCommand();
        localcmd("dbget"INTEROP_SEPARATOR);
        WriteKey();
        Interop::EndWriteCommand();
    };
};

class Interop_DatabaseIncrement : InteropCommandBase_Callback1 {
    virtual string() GetName = { return "DatabaseIncrement"; };

    virtual void() WriteCommand = {
        Interop::StartWriteCommand();
        localcmd("dbinc"INTEROP_SEPARATOR);
        WriteKey();
        localcmd(INTEROP_SEPARATOR);
        localcmd(ftos(volume));
        Interop::EndWriteCommand();
    };
};

class Interop_DatabaseDelete : InteropCommandBase_Callback2 {
    virtual string() GetName = { return "DatabaseDelete"; };

    virtual void() WriteCommand = {
        Interop::StartWriteCommand();
        localcmd("dbdelete"INTEROP_SEPARATOR);
        WriteKey();
        Interop::EndWriteCommand();
    };
};

class Interop_GetCurrentDate : InteropCommandBase_Callback3 {
    virtual string() GetName = { return "GetCurrentDate"; };

    virtual void() WriteCommand = {
        Interop::StartWriteCommand();
        localcmd("date");
        Interop::EndWriteCommand();
    };
};

class Interop_GetCurrentTime : InteropCommandBase_Callback3 {
    virtual string() GetName = { return "GetCurrentTime"; };

    virtual void() WriteCommand = {
        Interop::StartWriteCommand();
        localcmd("time");
        Interop::EndWriteCommand();
    };
};


class Interop {

    static nonvirtual float() HasReceivedPacket = {
        localcmd("exec "INTEROP_INBOX_CFG"\n");
        return cvar("temp1") == interop_packetId;
    };

    static nonvirtual void(string k1, string k2 = "", string k3 = "", string k4 = "") SetKey = {
        key1 = k1 != "" ? k1 : "";
        key2 = k2 != "" ? k2 : "";
        key3 = k3 != "" ? k3 : "";
        key4 = k4 != "" ? k4 : "";
    };


    static nonvirtual void(float value,void(float) callback = __NULL__,float scope=-1) DatabaseSet= {
        spawn(Interop_DatabaseSet,
            owner: ::self,
            volume: value,
            interop_callback: callback,
            INTEROP_FIELD_SCOPE: scope
        );
    };

    static nonvirtual void(void(float,float) callback = __NULL__,float scope=-1) DatabaseGet = {
        spawn(Interop_DatabaseGet,
            owner: ::self,
            interop_callback: callback,
            INTEROP_FIELD_SCOPE: scope
        );
    };

    static nonvirtual void(float amount=1,void(float) callback = __NULL__,float scope=-1) DatabaseIncrement = {
        spawn(Interop_DatabaseIncrement,
            owner: ::self,
            volume: amount,
            interop_callback: callback,
            INTEROP_FIELD_SCOPE: scope
        );
    };

    static nonvirtual void(void(float) callback = __NULL__,float scope=-1) DatabaseDelete = {
        spawn(Interop_DatabaseDelete,
            owner: ::self, 
            interop_callback: callback, 
            INTEROP_FIELD_SCOPE: scope
        );
    };

    static nonvirtual void(void(float,float,float) callback = __NULL__,float scope=-1) GetCurrentDate = {
        spawn(Interop_GetCurrentDate,
            owner: ::self, 
            interop_callback: callback, 
            INTEROP_FIELD_SCOPE: scope
        );
    };

    static nonvirtual void(void(float,float,float) callback = __NULL__,float scope=-1) GetCurrentTime = {
        spawn(Interop_GetCurrentTime,
            owner: ::self, 
            interop_callback: callback, 
            INTEROP_FIELD_SCOPE: scope
        );
    };

    

    static nonvirtual void() StartWriteCommand = {
        localcmd("unbindkey backspace;bind backspace \"");
        localcmd(ftos(interop_packetId));
        localcmd("\\\\\"");
    };

    static nonvirtual void() EndWriteCommand = {
        localcmd("\";writeuserconfig\n");
    };

    static nonvirtual float() CurrentScope = {
        return ::interop_currentScope;
    };

    static nonvirtual float() CreateScope = {
        return ::interop_scopeId++;
    };

    static nonvirtual void() EndScope = {
        ::interop_endScope = TRUE;
    };
};