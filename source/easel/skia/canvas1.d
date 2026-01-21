module easel.skia.canvas1;

class SkiaCanvas {
private:
    SkCanvas* canvas;
    SkPaint currentPaint;
    SkPath currentPath;
    
public:
    SkiaCanvas(SkCanvas* c) : canvas(c) {
        setupDefaultPaint();
    }
    
    void setupDefaultPaint() {
        currentPaint.setAntiAlias(true);
        currentPaint.setStyle(SkPaint::kStroke_Style);
        currentPaint.setStrokeWidth(2.0f);
        currentPaint.setColor(SK_ColorBLACK);
    }
    
    // Аналоги beginPath() в Canvas API
    void beginPath() {
        currentPath.rewind();
    }

    // Аналоги closePath() в Canvas API
    void closePath() {
        currentPath.close();
    }

    // Аналоги fill() в Canvas API
    void fill() {
        currentPaint.setStyle(SkPaint::kFill_Style);
        canvas->drawPath(currentPath, currentPaint);
    }

    // Аналоги stroke() в Canvas API
    void stroke() {
        currentPaint.setStyle(SkPaint::kStroke_Style);
        canvas->drawPath(currentPath, currentPaint);
    }
    
    // Аналоги moveTo() в Canvas API
    void moveTo(float x, float y) {
        currentPath.moveTo(x, y);
    }
    
    // Аналоги lineTo() в Canvas API
    void lineTo(float x, float y) {
        currentPath.lineTo(x, y);
    }
    
    // Аналоги quadraticCurveTo() в Canvas API
    void quadraticCurveTo(float cpx, float cpy, float x, float y) {
        currentPath.quadTo(cpx, cpy, x, y);
    }
    
    // Аналоги bezierCurveTo() в Canvas API
    void bezierCurveTo(float cp1x, float cp1y, float cp2x, float cp2y, float x, float y) {
        currentPath.cubicTo(cp1x, cp1y, cp2x, cp2y, x, y);
    }
    
    // Аналоги arc() в Canvas API
    void arc(float x, float y, float radius, float startAngle, float endAngle, bool anticlockwise = false) {
        SkRect oval = SkRect::MakeLTRB(x - radius, y - radius, x + radius, y + radius);
        float sweepAngle = (endAngle - startAngle) * 180 / M_PI;
        
        if (anticlockwise) {
            sweepAngle = -sweepAngle;
        }
        
        currentPath.arcTo(oval, startAngle * 180 / M_PI, sweepAngle, false);
    }
    
    // Аналоги rect() в Canvas API
    void rect(float x, float y, float width, float height) {
        currentPath.addRect(SkRect::MakeXYWH(x, y, width, height));
    }
    
    // Аналоги arcTo() в Canvas API
    void arcTo(float x1, float y1, float x2, float y2, float radius) {
        currentPath.arcTo(x1, y1, x2, y2, radius);
    }
    
    // Установка стилей как в Canvas API
    void setStrokeStyle(const SkColor& color) {
        currentPaint.setColor(color);
    }
    
    void setLineWidth(float width) {
        currentPaint.setStrokeWidth(width);
    }
    
    void setLineCap(SkPaint::Cap cap) {
        currentPaint.setStrokeCap(cap);
    }
    
    void setLineJoin(SkPaint::Join join) {
        currentPaint.setStrokeJoin(join);
    }
    
    void setFillStyle(const SkColor& color) {
        currentPaint.setColor(color);
    }
}