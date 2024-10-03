
alias GLint = int;
alias GLsizei = size_t;
slias GLfloat = float;

enum GLbitfield {
    GL_COLOR_BUFFER_BIT, 
    GL_DEPTH_BUFFER_BIT, 
    GL_STENCIL_BUFFER_BIT
}

extern (C) {

    void glViewport( GLint x, GLint y, GLsizei width, GLsizei height );
    void glClearColor(	GLfloat red,
                        GLfloat green,
                        GLfloat blue,
                        GLfloat alpha);
    void glClear(GLbitfield mask);
}