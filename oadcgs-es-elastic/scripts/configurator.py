# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This script is used to configure devices to be monitored by the
#          elastic data collector.  The tkinter python library is used
#          to create an HCI used by the installer to setup the devices for
#          monitoring.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: configurator.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Gary McKenzie, 2021-04-01: Original Version
#
# Site/System: All Sites where Logstash is installed
#
# Deficiency: N/A
#
# Use: This class is part of the elasticDataCollector python application
#      which runs as a service on Logstash VMs
#
# Users: Elastic Installer
#
# DAC Setting: 755 root root
#
# Frequency: Any time devices need to be configured for monitoring. Initially
#            during the installation and then any time devices are added/removed
#            from a site.
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
import json
from Crypt import Crypt
import os
import tkinter as tk
from tkinter import ttk
from tkinter import messagebox
import testaccess
import constants
import subprocess
from Device import DeviceType
from guiConstants import DescLabels


class Configurator(tk.Tk):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.master_list = []
        self.device_list = {"devices": self.master_list}
        self.display_list = []
        self.connectMethod = {}
        self.test_configuration = "/tmp/testconfig.json"

        self.configfile = constants.MAIN_DEVICE_CONF

        isfile = os.path.isfile(self.configfile)

        if isfile is True:
            with open(self.configfile, "r+") as devicefile:
                data = json.load(devicefile)
            devicefile.close()

            for device in data["devices"]:
                product = device["devicetype"] + " | " + device["hostname"]
                self.display_list.append(product)
                self.master_list.append(device)

        self.title("Data Collector Configuration Window")
        self.resizable(False, False)
        self.geometry("+600+300")
        self.rowconfigure(0, minsize=10, weight=1)

        self.configMainWindow()

        self.configEditPopup()
        self.editIndex = None

    def configMainWindow(self):
        # Create Combobox
        n = tk.StringVar()
        self.devicechooser = ttk.Combobox(
            self, state="readonly", width=27, textvariable=n
        )

        # <----Text Boxes---->
        # Main Window Text Boxes
        self.txt_usr = tk.Entry(self)
        self.txt_pass = tk.Entry(self, width=20)
        self.txt_priv_pass = tk.Entry(self, width=20)
        self.txt_url = tk.Entry(self)
        self.txt_host = tk.Entry(self)
        self.txt_ip = tk.Entry(self)

        # Places Cursor in the Username Window
        self.txt_usr.focus()

        # <----Labels---->
        # Main Window Labels
        self.lbl_usr = tk.Label(self, text="Username: ")
        self.lbl_pass = tk.Label(self, text="Password: ")
        self.lbl_priv_pass = tk.Label(self, text="Priv Password: ")
        self.lbl_url = tk.Label(self, text="URL: ")
        self.lbl_host = tk.Label(self, text="Display Name: ")
        self.lbl_ip = tk.Label(self, text="*Host: ")

        # Create List Box
        self.lb = tk.Listbox(self, width=30, height=15)

        # <---Reload Listbox---->
        for items in self.display_list:
            self.lb.insert(len(self.display_list), items)

        # Declare Global Labels
        self.lbl_select = ttk.Label(self, text="Select the Device: ")

        # Labels - Instructions
        self.lbl_instruct = tk.Label(
            self,
            text="----- Begin -----\nTo begin configuring devices, please select a device from the device window",
        )

        # Declare Buttons
        self.btn_config = tk.Button(
            self,
            width="10",
            height="2",
            text="Configure",
            bg="#228B22",
            fg="white",
            command=lambda: self.config(),
        )
        self.btn_clear = tk.Button(
            self,
            width="10",
            height="2",
            text="Clear",
            command=lambda: self.clear_textboxes(),
        )
        self.btn_cancel = tk.Button(
            self, width="10", height="2", text="Exit", command=self.destroy
        )
        self.btn_pub = tk.Button(
            self,
            width="10",
            height="2",
            text="Publish",
            bg="#228B22",
            fg="white",
            command=lambda: self.publish(),
        )
        self.btn_add = tk.Button(
            self,
            width="3",
            height="1",
            text="Add",
            bg="#228B22",
            fg="white",
            command=lambda: self.add_item(),
        )
        self.btn_delete = tk.Button(
            self,
            width="5",
            height="1",
            text="Del",
            bg="yellow",
            fg="black",
            command=lambda: self.del_item(),
        )
        self.btn_edit = tk.Button(
            self,
            width="5",
            height="1",
            text="Edit",
            bg="yellow",
            fg="black",
            command=lambda: self.edit_item(),
        )

        # Set Values for Combobox Drop Down
        self.devicechooser["values"] = DeviceType.get_device_types()
        for device in self.devicechooser["values"]:
            if (
                device == "isilon"
                or device == "xtremio"
                or device == "aruba"
                or device == "hbss_dlp"
            ):
                self.connectMethod[device] = "rest"
            else:
                self.connectMethod[device] = "snmp"

        # Send to Window / Grid Items
        self.lbl_select.grid(column=0, row=0, sticky="wn", padx=5, pady=30)
        self.devicechooser.grid(column=1, row=0, sticky="w", padx=0, pady=25)
        self.btn_add.grid(column=1, row=0, sticky="wn", padx=245, pady=25, columnspan=3)
        self.btn_delete.grid(column=2, row=4, sticky="ne", padx=5, pady=0)
        self.btn_edit.grid(column=2, row=4, sticky="nw", padx=5, pady=0, columnspan=3)
        self.lbl_instruct.grid(
            column=1, row=2, sticky="nw", padx=5, pady=15, columnspan=5
        )

        # Seperator Object
        self.seperator_top1 = ttk.Separator(self)
        self.seperator_top2 = ttk.Separator(self)
        self.seperator_bottom1 = ttk.Separator(self)

        self.seperator_top1.grid(column=0, row=1, columnspan=9, sticky="ew")
        self.seperator_top2.grid(column=0, row=3, columnspan=9, sticky="ew")
        self.seperator_bottom1.grid(column=0, row=10, columnspan=9, sticky="ew")

        self.btn_config.grid(column=0, row=11, sticky="nw", padx=5, pady=5)
        self.btn_clear.grid(column=1, row=11, sticky="nw", padx=5, pady=5)
        self.btn_cancel.grid(column=3, row=11, sticky="n", padx=0, pady=5, columnspan=3)
        self.btn_pub.grid(column=1, row=11, sticky="n", padx=120, pady=5)

        self.lb.grid(
            column=2, row=4, sticky="nw", padx=5, pady=30, rowspan=7, columnspan=3
        )

    def configEditPopup(self):
        self.edit = tk.Toplevel(self)
        self.edit.title("Edit Item")
        self.edit.rowconfigure(0, minsize=10, weight=1)
        self.edit.resizable(False, False)
        self.edit.geometry("+800+500")

        # Create Save and Cancel Button
        self.editSave = tk.Button(
            self.edit,
            width="10",
            height="2",
            text="Save",
            bg="#228B22",
            fg="white",
            command=lambda: self.edit_save(),
        )
        self.editCancel = tk.Button(
            self.edit,
            width="10",
            height="2",
            text="Cancel",
            bg="#DC143C",
            fg="white",
            command=lambda: self.edit_close(),
        )
        self.editSave.grid(column=0, row=8, sticky="nw", padx=5, pady=5)
        self.editCancel.grid(column=1, row=8, sticky="ne", padx=5, pady=5)

        # Text Boxes
        self.switchdevices = ttk.Combobox(self.edit, state="readonly", width=19)
        self.txt_edit_usr = tk.Entry(self.edit)
        self.txt_edit_pass = tk.Entry(self.edit, show="*", width=20)
        self.txt_edit_privpass = tk.Entry(self.edit, show="*", width=20)
        self.txt_edit_url = tk.Entry(self.edit)
        self.txt_edit_host = tk.Entry(self.edit)
        self.txt_edit_ip = tk.Entry(self.edit)

        # Places Cursor in the Username window
        self.txt_edit_usr.focus()

        # Labels
        self.lbl_edit_device = tk.Label(self.edit, text="Device Name: ")
        self.lbl_edit_usr = tk.Label(self.edit, text="Username: ")
        self.lbl_edit_pass = tk.Label(self.edit, text="Password: ")
        self.lbl_edit_privpass = tk.Label(self.edit, text="PrivPass: ")
        self.lbl_edit_url = tk.Label(self.edit, text="URL: ")
        self.lbl_edit_host = tk.Label(self.edit, text="Display Name: ")
        self.lbl_edit_ip = tk.Label(self.edit, text="*Host: ")

        # Send Labels to Edit Window
        self.lbl_edit_device.grid(row=1, column=0, sticky="wn", padx=18, pady=10)
        self.lbl_edit_usr.grid(row=2, column=0, sticky="wn", padx=18, pady=15)
        self.lbl_edit_pass.grid(row=3, column=0, sticky="wn", padx=18, pady=10)
        self.lbl_edit_url.grid(row=5, column=0, sticky="wn", padx=18, pady=10)
        self.lbl_edit_host.grid(row=6, column=0, sticky="wn", padx=18, pady=10)
        self.lbl_edit_ip.grid(row=7, column=0, sticky="wn", padx=18, pady=10)

        # Send Text to Edit Window
        self.switchdevices.grid(row=1, column=1, sticky="wn", padx=20, pady=15)
        self.txt_edit_usr.grid(row=2, column=1, sticky="wn", padx=20, pady=15)
        self.txt_edit_pass.grid(row=3, column=1, sticky="wn", padx=20, pady=15)
        self.txt_edit_url.grid(row=5, column=1, sticky="wn", padx=20, pady=15)
        self.txt_edit_host.grid(row=6, column=1, sticky="wn", padx=20, pady=15)
        self.txt_edit_ip.grid(row=7, column=1, sticky="wn", padx=20, pady=15)

        self.edit.withdraw()

    def add_entry(self, usr, passwd, privpasswd, url, hostname, ip, selection, isedit):
        success = False

        if len(usr) == 0:
            messagebox.showinfo("Input", "User name required.")
        elif len(url) == 0:
            messagebox.showinfo("Input", "url required.")
        elif len(hostname) == 0:
            messagebox.showinfo("Input", "Display name required.")
        elif len(ip) == 0:
            messagebox.showinfo("Input", "resolvable ip/hostname required.")
        else:
            entry = {
                "passwd": passwd,
                "hostname": hostname,
                "url": url,
                "host": ip,
                "devicetype": selection,
                "user": usr,
                "timeout": 5000000,
            }

            if self.connectMethod[selection] == "rest":
                if selection == DeviceType.ISILON:
                    entry["port"] = 8080
                elif selection == DeviceType.DLP:
                    entry["port"] = 8007
                else:
                    entry["port"] = 443
            else:
                entry["privPass"] = privpasswd
                entry["port"] = 161

            product = entry["devicetype"] + " | " + entry["hostname"]
            self.display_list.append(product)

            # <----Append to Master JSON List & Display List---->
            self.master_list.append(entry)

            if isedit:
                # <----Delete Older Index from Display & Master List---->
                del self.display_list[self.editIndex]
                del self.master_list[self.editIndex]

            # <----Empty Listboxes---->
            self.lb.delete(0, tk.END)

            # <----Reload Listboxes---->
            for widget in self.display_list:
                self.lb.insert(len(self.display_list), widget)
            success = True

        return success

    def edit_save(self):
        # Add Access to Original Values
        edit_array = dict(self.master_list[self.editIndex])

        usr = self.txt_edit_usr.get()
        passwd = self.txt_edit_pass.get()
        privpasswd = self.txt_edit_privpass.get()
        url = self.txt_edit_url.get()
        hostname = self.txt_edit_host.get()
        ip = self.txt_edit_ip.get()
        selection = self.switchdevices.get()
        if passwd != edit_array["passwd"]:
            print(f"encrypting passwd:{passwd}")
            passwd = str(Crypt().encode(passwd))
        if (
            self.connectMethod[selection] == "snmp"
            and privpasswd != edit_array["privPass"]
        ):
            privpasswd = str(Crypt().encode(privpasswd))

        if self.add_entry(usr, passwd, privpasswd, url, hostname, ip, selection, True):
            self.edit.withdraw()
            self.deiconify()

    def edit_item(self):
        self.clear_editboxes()

        try:
            self.editIndex = int(self.lb.curselection()[0])
            seltext = self.lb.get(self.editIndex)

            switchdevices = None

            edit_array = dict(self.master_list[self.editIndex])
            save_control = edit_array["devicetype"]

            if self.editIndex != "":
                # Put Edit Items in Text Boxes
                self.switchdevices.set(edit_array["devicetype"])
                self.switchdevices.configure(state="disabled")
                self.txt_edit_usr.insert(0, edit_array["user"])
                self.txt_edit_pass.insert(0, edit_array["passwd"])
                self.txt_edit_url.insert(0, edit_array["url"])
                self.txt_edit_host.insert(0, edit_array["hostname"])
                self.txt_edit_ip.insert(0, edit_array["host"])

                if self.connectMethod[edit_array["devicetype"]] == "snmp":
                    # Send to edit window
                    self.lbl_edit_privpass.grid(
                        row=4, column=0, sticky="wn", padx=18, pady=10
                    )
                    self.txt_edit_privpass.grid(
                        row=4, column=1, sticky="wn", padx=20, pady=15
                    )
                    self.txt_edit_privpass.insert(0, edit_array["privPass"])
                else:
                    self.lbl_edit_privpass.grid_remove()
                    self.txt_edit_privpass.grid_remove()

                if (
                    edit_array["devicetype"] == "nexus5k"
                    or edit_array["devicetype"] == "nexus7k"
                    or edit_array["devicetype"] == "catalyst"
                ):
                    ## Device List Combo Box ##
                    self.switchdevices["values"] = ("nexus5k", "nexus7k", "catalyst")
                    self.switchdevices.configure(state="enabled")
                    self.switchdevices.set(save_control)  # Sets current index option

                self.withdraw()
                self.edit.deiconify()
                self.update_idletasks()

        except:
            messagebox.showinfo("Edit", "No item selected for edit.")

    def edit_close(self):
        self.edit.withdraw()
        self.deiconify()

    def config(self):
        selection = self.devicechooser.get()

        # <----Get User Inputs---->
        user = self.txt_usr.get()
        passwd = str(Crypt().encode(self.txt_pass.get()))
        privpasswd = str(Crypt().encode(self.txt_priv_pass.get()))
        url = self.txt_url.get()
        hostname = self.txt_host.get()
        ip = self.txt_ip.get()

        if self.add_entry(
            user, passwd, privpasswd, url, hostname, ip, selection, False
        ):
            self.clear_textboxes()

    def clear_editboxes(self):
        self.switchdevices.delete(0, tk.END)
        self.txt_edit_usr.delete(0, tk.END)
        self.txt_edit_pass.delete(0, tk.END)
        self.txt_edit_privpass.delete(0, tk.END)
        self.txt_edit_url.delete(0, tk.END)
        self.txt_edit_host.delete(0, tk.END)
        self.txt_edit_ip.delete(0, tk.END)

    def clear_textboxes(self):
        self.txt_usr.delete(0, tk.END)
        self.txt_pass.delete(0, tk.END)
        self.txt_priv_pass.delete(0, tk.END)
        self.txt_url.delete(0, tk.END)
        self.txt_host.delete(0, tk.END)
        self.txt_ip.delete(0, tk.END)

    def result_confirm(self, results_window):
        results_window.destroy()
        self.deiconify()

    def get_screencenter(self, width, height):
        screen_width = self.winfo_screenwidth()
        screen_height = self.winfo_screenheight()
        x = (screen_width - width) // 2
        y = (screen_height - height) // 2
        return f"{width}x{height}+{x}+{y}"

    def show_notification(self):
        notify = tk.Toplevel(self)
        notify.overrideredirect(True)
        notify.resizable(False, False)
        notify.geometry(self.get_screencenter(300, 100))
        notify.protocol("WM_DELETE_WINDOW", lambda: None)
        notify.attributes("-topmost", True)
        notify_label = tk.Label(notify, text="Validating configurations\n Please wait.")
        notify_label.pack(pady=10)
        return notify

    def publish(self):
        # <----Close Main Window | Open Results---->
        self.withdraw()
        notify_window = self.show_notification()
        self.update()

        results_window = tk.Tk()
        results_window.title("Results")
        results_window.resizable(False, False)
        results_window.geometry(self.get_screencenter(300, 600))
        result_list = []
        lbl_success_notice = tk.Label(
            master=results_window,
            text="Success! All Devices were configured!",
            fg="#228B22",
        )
        lbl_failure_notice = tk.Label(
            master=results_window,
            text="Failure! One or more devices failed to connect.\n Please check your configurations and try again!",
            fg="#DC143C",
        )

        # <----Create Listbox & Confirm Button---->
        result_lb = tk.Listbox(results_window, width=35, height=25)
        btn_confirm = tk.Button(
            master=results_window,
            width="10",
            height="2",
            text="Continue",
            command=lambda: self.result_confirm(results_window),
        )

        # <----Send List & Button to Layout---->
        result_lb.grid(
            column=0, row=0, sticky="n", padx=5, pady=15, rowspan=5, columnspan=3
        )
        btn_confirm.grid(column=1, row=6, sticky="n", padx=10, pady=15)

        with open(self.test_configuration, "w") as outfile:
            json.dump(self.device_list, outfile, indent=4)
        outfile.close()

        # <----Run Testaccess & Return List---->
        res_dict, out_list = testaccess.main()

        false_counter = 0
        true_counter = 0

        for item in res_dict:
            if item is "False":
                false_counter += 1

            if item is "True":
                true_counter += 1

        for items in out_list:
            result_lb.insert(len(out_list), items)

        notify_window.destroy()

        if false_counter == 0:
            os.remove(self.test_configuration)

            with open(self.configfile, "w") as outfile:
                json.dump(self.device_list, outfile, indent=4)
            outfile.close()
            lbl_success_notice.grid(column=1, row=5, sticky="n", padx=10, pady=15)
            subprocess.call(
                ["sudo", "systemctl", "restart", "elasticDataCollector.service"]
            )
        else:
            os.remove(self.test_configuration)
            lbl_failure_notice.grid(column=1, row=5, sticky="n", padx=10, pady=15)

    def add_item(self):
        try:
            selection = self.devicechooser.get()
            self.lbl_instruct["text"] = DescLabels[selection]

            # Clear Text Boxes
            self.clear_textboxes()

            # <----Send to Window---->
            self.lbl_usr.grid(row=4, column=0, sticky="wn", padx=15, pady=15)
            self.lbl_pass.grid(row=5, column=0, sticky="wn", padx=15, pady=10)
            self.lbl_priv_pass.grid(row=6, column=0, sticky="wn", padx=15, pady=10)
            self.lbl_url.grid(row=7, column=0, sticky="wn", padx=15, pady=10)
            self.lbl_host.grid(row=8, column=0, sticky="wn", padx=15, pady=10)
            self.lbl_ip.grid(row=9, column=0, sticky="wn", padx=15, pady=10)

            self.txt_usr.grid(row=4, column=1, sticky="wn", padx=0, pady=15)
            self.txt_pass.grid(row=5, column=1, sticky="wn", padx=0, pady=15)
            self.txt_priv_pass.grid(row=6, column=1, sticky="wn", padx=0, pady=15)
            self.txt_url.grid(row=7, column=1, sticky="wn", padx=0, pady=15)
            self.txt_host.grid(row=8, column=1, sticky="wn", padx=0, pady=15)
            self.txt_ip.grid(row=9, column=1, sticky="wn", padx=0, pady=15)

            if self.connectMethod[selection] == "rest":
                self.lbl_priv_pass.grid_remove()
                self.txt_priv_pass.grid_remove()

        except:
            messagebox.showinfo("Select", "No item selected to add.")

    def del_item(self):
        try:
            index = int(self.lb.curselection()[0])
            seltext = self.lb.get(index)
            del self.display_list[index]
            del self.master_list[index]

            # <----Empty Listboxes---->
            self.lb.delete(0, tk.END)

            # <----Reload Listboxes---->
            for widget in self.display_list:
                self.lb.insert(len(self.display_list), widget)

        except:
            messagebox.showinfo("Del", "No item selected for delete.")


def main():
    app = Configurator()
    app.mainloop()


if __name__ == "__main__":
    main()

#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
