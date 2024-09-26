import widget_way;

void main()
{
    try {
        auto app = new App;
        app.run();
    }
    catch(Exception e) {
        writeln(e.msg);
    }
}