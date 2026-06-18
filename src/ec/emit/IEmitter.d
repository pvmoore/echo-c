module ec.emit.IEmitter;

import ec.all;

public:

import ec.emit.api.APIEmitter;
import ec.emit.echo.CEmitter;

interface IEmitter {
    void emit(CFile cfile);
}
