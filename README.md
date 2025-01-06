# VIOLA: A Framework for the Automatic Generation of Virtual Analog Audio Plug-ins based on Wave Digital Filters

Welcome to the official repository for **VIOLA**, a framework designed for the **automatic generation of virtual analog audio plug-ins** using **Wave Digital Filters (WDFs)**. This repository accompanies our paper:  
*"VIOLA: A Framework for the Automatic Generation of Virtual Analog Audio Plug-ins based on WDFs,"* authored by R. Giampiccolo, S. Ravasi, and A. Bernardini, and submitted to the special issue "The Sound of Digital Audio Effects" of the *Journal of the Audio Engineering Society*.

---

## 📖 About VIOLA

VIOLA simplifies the creation of Virtual Analog audio plug-ins, exploiting the modularity and efficiency of WDFs. Users just have to draw a circuit in LTspice and that's it: VIOLA will generate the audio plug-in making use of the MATLAB Audio Toolbox for the automatic design of the graphic user interface and the conversion of code to C++.

### Features

- **Automatic Plug-in Creation**: Simplify the creation of virtual analog plug-ins from your circuit designs.  
- **Custom LTspice Library**: Design circuits easily with a tailored library of components.  
- **Pre-Built Examples**: Start experimenting with ready-to-use examples.  
- **Audio Examples**: Explore audio demonstrations to hear VIOLA's capabilities.

### Current Status

- **Windows OS**: The codebase is fully functional and available for use.  
- **MacOS Support**: The codebase is fully functional and available for use.

### Requirements

- **Matlab R2024a or Later**: The tool has been developed with version R2024a.
- **Matlab Audio Toolbox**: Fundamental to access "audioPlugin" class and realted subclasses.
- **Matlab Coder**: Automatic C++ code generation and plugin deployment.
- **Supported C++ Coder**: More information about can be found at [Supported compilers](https://it.mathworks.com/support/requirements/supported-compilers.html).
- **MacOS Users**: update and/or install Xcode v16. Then, run `sudo xcode-select -switch <path-to-xcode.app>` in your terminal. In Matlab's command window run:
  ```
  mex -setup C++
  mex -setup C
  ```

---

## 🎸 Audio Examples

Discover the power of VIOLA by listening to **audio examples** on our [GitHub page](https://polimi-ispl.github.io/viola/).

---

## 🛠️ LTspice Component Library

Design and simulate circuits in LTspice using the **custom component library** provided:

- Find the library files in the `ltspice_custom_components/` directory.
- Copy all the files inside the directory of your .asc file. The circuit symbols of custom components are in the file `ltspice_custom_components/CustomComponents.asc`. 
- Explore example circuits in the `windows/Data/Input/Netlist/` directory.
- Test the pre-built audio plug-ins of the `windows/Results/` directory in your DAWs.

---

## :memo: Rules for Schematic Design

To draw compatible schematics on LTspice for VIOLA, some rules must be respected:

- The input signal can be specified as a voltage/current source using the name "Vin" or "Iin".
- Only one input signal can be provided (all the generated plugins are mono).
- Eventual DC voltage/current source name can be left unaltered (V1, V2, etc.).
- Do not assign the same name to different components (e.g., having two resistors named "R1" will give an error).
- Do not rename the nodes (leave the SPICE labeling: N001, N002, etc.). To specify the output node in MATLAB main write down the right node from LTspice and specify it as a string (e.g., "N005").
- Custom element names must be declared as follows: D (diodes), Dser (diode series), Dap (antiparallel diodes), Plin (lin potentiometers), Plog (log potentiometers), Pilog (inv-logc potentiometers), OA (ideal opamps). Then, a number has to be added after each label to distinguish the different components. 
- Specify diode parameters in the following order: Is, eta, Vth, Rs, Rp (e.g., Is=4.352n eta=1.905 Vth=25.8563m Rs=1m Rp=1Meg).
- Series and antiparallel combinations on diodes also require the addition of the parameter n (to account for the number of diodes in series).
- Assign progressive numbers to potentiometers, even though they differ in type (e.g., "Plin1", "Plog2", "Plin3", etc.).
- Specify potentiometer parameters in the right order: Rp, x (e.g., Rp=100k x=0.75).

---

## 📅 Roadmap

- **Additional Examples**: New circuit designs will be added.
- **Efficiency Enhancements**: Codebase will be refactored and improved.
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
**stefanoravasi98@gmail.com**

---

## 📜 License

This project is licensed under the **GPL-3.0 License**. See the `LICENSE` file for more details.
