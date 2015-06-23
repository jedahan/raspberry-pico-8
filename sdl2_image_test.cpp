#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <iostream>

// Manage error messages
void check_error_sdl(bool check, const char* message);
void check_error_sdl_img(bool check, const char* message);

// Load an image from "fname" and return an SDL_Texture with the content of the image
SDL_Texture* load_texture(const char* fname, SDL_Renderer *renderer);


int main(int argc, char** argv) {
    // Initialize SDL
    check_error_sdl(SDL_Init(SDL_INIT_VIDEO) != 0, "Unable to initialize SDL");

    // Create and initialize a 800x600 window
    SDL_Window* window = SDL_CreateWindow("Test SDL 2", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                          800, 600, SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL);
    check_error_sdl(window == nullptr, "Unable to create window");

    // Create and initialize a hardware accelerated renderer that will be refreshed in sync with your monitor (at approx. 60 Hz)
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    check_error_sdl(renderer == nullptr, "Unable to create a renderer");

    // Set the default renderer color to corn blue
    SDL_SetRenderDrawColor(renderer, 100, 149, 237, 255);

    // Initialize SDL_img
    int flags=IMG_INIT_JPG | IMG_INIT_PNG;
    int initted = IMG_Init(flags);
    check_error_sdl_img((initted & flags) != flags, "Unable to initialize SDL_image");

    // Load the image in a texture
    SDL_Texture *texture = load_texture("img_test.png", renderer);

    // We need to create a destination rectangle for the image (where we want this to be show) on the renderer area
    SDL_Rect dest_rect;
    dest_rect.x = 50; dest_rect.y = 50;
    dest_rect.w = 337; dest_rect.h = 210;

    // Clear the window content (using the default renderer color)
    SDL_RenderClear(renderer);

    // Copy the texture on the renderer
    SDL_RenderCopy(renderer, texture, NULL, &dest_rect);

    // Update the window surface (show the renderer)
 SDL_RenderPresent(renderer);

    // Wait for 10 seconds
    SDL_Delay(10000);

    // Clear the allocated resources
    SDL_DestroyTexture(texture);
    IMG_Quit();
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}

// In case of error, print the error code and close the application
void check_error_sdl(bool check, const char* message) {
    if (check) {
        std::cout << message << " " << SDL_GetError() << std::endl;
        SDL_Quit();
        std::exit(-1);
    }
}

// In case of error, print the error code and close the application
void check_error_sdl_img(bool check, const char* message) {
    if (check) {
        std::cout << message << " " << IMG_GetError() << std::endl;
        IMG_Quit();
        SDL_Quit();
        std::exit(-1);
    }
}

// Load an image from "fname" and return an SDL_Texture with the content of the image
SDL_Texture* load_texture(const char* fname, SDL_Renderer *renderer) {
    SDL_Surface *image = IMG_Load(fname);
    check_error_sdl_img(image == nullptr, "Unable to load image");

    SDL_Texture *img_texture = SDL_CreateTextureFromSurface(renderer, image);
    check_error_sdl_img(img_texture == nullptr, "Unable to create a texture from the image");
    SDL_FreeSurface(image);
    return img_texture;
}
