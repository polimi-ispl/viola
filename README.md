# VIOLA: A Framework for the Automatic Generation of Virtual Analog Audio Plug-ins based on WDFs

Welcome to the official repository for **VIOLA**, a framework designed for the **automatic generation of virtual analog audio plug-ins** using **Wave Digital Filters (WDFs)**. This repository accompanies our paper:  
*"VIOLA: A Framework for the Automatic Generation of Virtual Analog Audio Plug-ins based on WDFs,"* authored by R. Giampiccolo, S. Ravasi, and A. Bernardini, and submitted to the special issue "The Sound of Digital Audio Effects" of the *Journal of the Audio Engineering Society*.

---

## 📖 About VIOLA

VIOLA simplifies the creation of Virtual Analog audio plug-ins, exploiting the modularity and efficiency of WDFs. Users just have to draw a circuit in LTspice and that's it: VIOLA will generate the audio plug-in making use of the MATLAB Audio Toolbox for the automatic desing of the graphic user interface and the conversion of code to C++.

### Features

- **Automatic Plug-in Creation**: Simplify the creation of virtual analog plug-ins from your circuit designs.  
- **Custom LTspice Library**: Design circuits easily with a tailored library of components.  
- **Pre-Built Examples**: Start experimenting with ready-to-use examples.  
- **Audio Examples**: Explore audio demonstrations to hear VIOLA's capabilities.

### Current Status

- **Windows OS**: The codebase is fully functional and available for use.  
- **MacOS Support**: Coming soon.

---

## 🎸 Audio Examples

Discover the power of VIOLA by listening to **audio examples** included . Navigate to the `audio_examples/` directory to hear the results of virtual analog processing.

---

## 🛠️ LTspice Component Library

Design and simulate circuits in LTspice using the **custom component library** provided:

- Find the library files in the `ltspice_custom_components/` directory.  
- Explore example circuits in the `VIOLA/Data/Input/Netlist/` directory.
- Use pre-built components of the `compiled_win/` directory in your DAWs.

---

## 📅 Roadmap

- **MacOS Support**: Coming soon—stay tuned!  
- **Additional Examples**: New circuit designs will be added.
- **Additional Components**: New circuit components will be added. 

---

## 🤝 Contributing

We welcome contributions! Feel free to:

- Report issues.  
- Request features.  
- Submit pull requests.

---

## 📧 Contact

For inquiries or feedback, reach out via email:  
**riccardo.giampiccolo@polimi.it**
**stefano.ravasi@mail.polimi.it**

---

## 📜 License

This project is licensed under the **MIT License**. See the `LICENSE` file for more details.
