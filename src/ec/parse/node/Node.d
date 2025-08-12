module ec.parse.node.Node;

import ec.all;

abstract class Node {
public:
    Node[] children;
    Node parent;

    // Overridable methods
    bool isResolved() { return true; }

    final bool hasChildren() { return children.length > 0; }
    final int numChildren() { return children.length.as!int; }

    final Node first() { return children[0]; }
    final Node last() { return children[$-1]; }

    final bool isLast() { return parent && parent.hasChildren() && parent.last() is this; }

    final void add(Node n) {
        if(n.parent) {
            n.detach();
        }
        children ~= n;
        n.parent = this;
    }
    final int index() {
        if(parent is null) return -1;
        return parent.children.indexOf(this);
    }
    final void detach() {
        int i = index();
        if(i != -1) {
            parent.children.removeAt(i);
            parent = null;
        }
    }
    final CFile getCFile() {
        if(CFile cf = this.as!CFile) return cf;
        return parent.getCFile();
    }
    final void dump(string indent = "") {
        log("%s%s", indent, this);
        foreach(ch; children) {
            ch.dump(indent ~ "  ");
        }
    }
    final string dumpToString(string indent = "") {
        string s = "%s%s\n".format(indent, this);
        foreach(ch; children) {
            s ~= ch.dumpToString(indent ~ "  ");
        }
        return s;
    }

protected:

private:
}
