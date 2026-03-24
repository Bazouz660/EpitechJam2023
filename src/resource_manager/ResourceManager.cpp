/*
** EPITECH PROJECT, 2023
** Jam
** File description:
** ResourceManager
*/

#include <filesystem>
#include "ResourceManager.hpp"
#include "parsing.hpp"

namespace jam
{

    ResourceManager::ResourceManager()
    {
        loadAssets();
    }

    void ResourceManager::loadAssets()
    {
        loadFont("debugFont", "asset/font/debug_font.ttf");
        loadFont("gameFont", "asset/font/game_font.ttf");
        loadFont("nathanFont", "asset/font/Nathan.ttf");

        loadSoundBuffer("tick", "asset/audio/tick.ogg");
        loadSoundBuffer("valid", "asset/audio/valid.ogg");
        loadSoundBuffer("invalid", "asset/audio/invalid.ogg");
        loadSoundBuffer("typing", "asset/audio/typing.ogg");
        loadSoundBuffer("curtain_slide", "asset/audio/curtain_slide.ogg");
        loadSoundBuffer("clapping", "asset/audio/clapping.ogg");
        loadSoundBuffer("meh", "asset/audio/meh.ogg");
        loadSoundBuffer("lose", "asset/audio/lose.ogg");

        loadMusic("harry_potter", "asset/audio/Harry_Potter.ogg");
        loadMusic("menu", "asset/audio/menu_music.ogg");
        loadMusic("pokemon", "asset/audio/pokemon.ogg");
        loadMusic("toy_story", "asset/audio/toy_story.ogg");
        loadMusic("stranger_things", "asset/audio/stranger_things.ogg");
        loadMusic("credits", "asset/audio/credits.ogg");

        loadTexture("menu_bg", "asset/texture/menu_bg.png");
        loadTexture("generic_button", "asset/texture/generic_button.png");
        loadTexturesFromFolder("asset/texture/rooms");
        loadTexture("cursor loupe", "asset/texture/loupe.png");
        loadTexture("curtains", "asset/texture/curtains.png");
        loadTexture("tick_box", "asset/texture/tickBox.png");
        loadTexture("credits_bg", "asset/texture/credits_bg.png");
        loadTexture("monty_python", "asset/texture/monty_python.jpg");
    }

    ResourceManager &ResourceManager::getInstance()
    {
        static ResourceManager instance;
        return instance;
    }

    void ResourceManager::loadTexture(const std::string &name, const std::string &filename)
    {
        // Create a new texture and load it from the specified file.
        sf::Texture texture;
        texture.loadFromFile(filename);

        std::cout << "Loaded texture as \"" << name << "\" from "
                  << "\"" + filename + "\"" << std::endl;

        // Insert the texture into the map using the name as the key.
        m_textures[name] = texture;
        m_images[name] = texture.copyToImage();
    }

    sf::Texture &ResourceManager::getTexture(const std::string &name)
    {
        return m_textures.at(name);
    }

    sf::Image &ResourceManager::getTextureImage(const std::string &name)
    {
        return m_images.at(name);
    }

    void ResourceManager::loadTexturesFromFolder(const std::string &directory)
    {
        for (const auto &entry : std::filesystem::directory_iterator(directory))
            loadTexture(removeExtension(entry.path().filename().string()), entry.path().string());
    }

    void ResourceManager::loadFont(const std::string &name,
                                   const std::string &filePath)
    {
        auto &font = m_fonts[name];
        if (!font.loadFromFile(filePath))
            throw std::runtime_error("Failed to load font: " + filePath);
        m_fonts[name] = font;
        std::cout << "Loaded font as \"" << name << "\" from "
                  << "\"" + filePath + "\"" << std::endl;
    }

    sf::Font &ResourceManager::getFont(const std::string &fontName)
    {
        if (m_fonts.count(fontName) == 0)
            m_fonts[fontName].loadFromFile(fontName);
        return m_fonts.at(fontName);
    }

    void ResourceManager::loadSoundBuffer(const std::string &name,
                                          const std::string &fileName)
    {
        sf::SoundBuffer soundBuffer;
        if (!soundBuffer.loadFromFile(fileName))
            throw std::runtime_error("Failed to load sound buffer: " + fileName);
        m_soundBuffers[name] = soundBuffer;
        std::cout << "Loaded font as \"" << name << "\" from "
                  << "\"" + fileName + "\"" << std::endl;
    }

    sf::SoundBuffer &ResourceManager::getSoundBuffer(const std::string &name)
    {
        auto it = m_soundBuffers.find(name);
        if (it == m_soundBuffers.end())
            throw std::runtime_error("Sound buffer not found: " + name);
        return m_soundBuffers.at(name);
    }

    void ResourceManager::loadMusic(const std::string &name, const std::string &filePath)
    {
        std::unique_ptr<sf::Music> music = std::make_unique<sf::Music>();

        if (!music->openFromFile(filePath))
            throw std::runtime_error("Failed to load music: " + filePath);
        m_musics[name] = std::move(music);
        std::cout << "Loaded music as \"" << name << "\" from "
                  << "\"" + filePath + "\"" << std::endl;
    }

    sf::Music &ResourceManager::getMusic(const std::string &name)
    {
        if (m_musics.count(name) == 0)
            m_musics[name] = std::make_unique<sf::Music>();
        return *m_musics.at(name);
    }

}