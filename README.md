# ELK Auto-Installer

This script automates the installation and configuration of Elasticsearch and Kibana for the ELK stack. It detects the operating system and package manager to ensure compatibility.

## Prerequisites

- CentOS 7 or higher, Ubuntu, Debian, Red Hat, Fedora
- Root or sudo access

## Usage

1. Clone the repository:

    ```bash
    git clone https://github.com/rahul4tech/ELK-Auto-Installer.git
    ```

2. Change into the directory:

    ```bash
    cd ELK-Auto-Installer
    ```

3. Run the script:

    ```bash
    chmod +x ELK-Auto-Installer.sh
    ```
4. Run the script:

    ```bash
    ./ELK-Auto-Installer.sh
    ```

    ```bash

    If you prefer not to clone the repository, you can also run the script directly from wget or curl:

    ### Using WGET
    ```bash
    wget https://raw.githubusercontent.com/rahul4tech/ELK-Auto-Installer/master/ELK-Auto-Installer.sh && chmod +x ELK-Auto-Installer.sh && ./ELK-Auto-Installer.sh
    ```
    ### Using CURL

    ```bash    
    curl -O https://raw.githubusercontent.com/rahul4tech/ELK-Auto-Installer/master/ELK-Auto-Installer.sh && chmod +x ELK-Auto-Installer.sh && ./ELK-Auto-Installer.sh
    ```

4. Follow the on-screen instructions to install, remove, or manage users for Elasticsearch and Kibana.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Notes

- Make sure to review the script and adjust any settings or configurations as needed for your environment.
- User management features require Elasticsearch's security features to be enabled and properly configured.


## Author
Rahul Sinha