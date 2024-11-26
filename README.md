# Translucent Skin Shader

A translucent human skin shader, that I created in Unity 2021.3.9f1 using HLSL. 
Concepts used include the Blinn-Phong reflection model, normal mapping and translucency.

The project was done in collaboration with Frederik Stappert - he found the research papers and mathematical formulas that we needed and I programmed and implemented the shader.

## Front and back view of the shader

![FRONT_SkinShader](https://github.com/user-attachments/assets/63567bc5-de0e-4f51-9a04-31398b3caad3)
<img src="https://github.com/user-attachments/assets/95f0e35b-fba9-4faf-abef-d1eb668fc7b9" alt="Alt Text" width="357" height="317">

## Default and recommended settings for the shader

![SETTINGS_SkinShader](https://github.com/user-attachments/assets/9b4b561f-216a-4d19-a4fa-23ec33508d9c)

## Theory implemented in the shader

### 1) Blinn-Phong Reflection model formula

![BlinnPhong](https://github.com/user-attachments/assets/ca53b27b-c458-4d96-8fa9-8e8ebcbcc710)
![BlinnPhong_FORMULA_correct](https://github.com/user-attachments/assets/4b45f606-5a02-4b63-9f99-7cd0ba00458d)

### 2) Normal map calculation formula

![NormalMap](https://github.com/user-attachments/assets/4dde2802-1a4f-4159-9d1a-21850f0eda14)

### 3) Translucency formula

![Translucency](https://github.com/user-attachments/assets/113dbdad-a291-440c-ad32-e666cc57019b)
![Translucency_FORMULA](https://github.com/user-attachments/assets/7c4b6ba8-6237-4d28-9094-c729c14df9a9)
