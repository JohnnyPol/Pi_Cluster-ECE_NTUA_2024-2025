# SLURM Information and Code
In order to see info about node or partition status execute **sinfo** and for more detailed one execute **scontrol show nodes**.
At first, sinfo printed that all states of devices is UNKNOWN and to solve it use copy_munge_key playbook which copies the munge key from master node to all workers,
then restarts both munge and slurmd. Furthermore, red1 device was stuck at comp state and as a solution we ranQ
1. sudo scontrol update NodeName=red1 State=DOWN Reason="Resetting"
2. sudo scontrol update NodeName=red1 State=RESUME
The hostnames of client PIs were changed so SLURM Server can access them. For example, a change from red3 to "red3" is necessary and hpc_master is now called "master".
The changes can be done via the following lines of code
- sudo hostnamectl set-hostname <new-hostname>
- sudo vim /etc/hosts
- > add new line 127.0.1.1 <new-hostname>

Our team followed [this link](https://github.com/ReverseSage/Slurm-ubuntu-20.04.1) for the installation of SLURM.
* Common user with id 1100 and sudo permissions in all nodes (NIS server on hpc_master)
* Synchronize time across all nodes using chrony 
* Common nfs directory 
* Munge and slurm users and groups across all nodes
* Passwordless ssh from master to all workers
* Install munge package master and workers
* MariaDB installation/setup(above link provides github repo with configs)
* Install slurm (master/workers)
* Configure slurm
* Test benchmark
* Test MPI
  
The process for red6 machine is depicted below:
1. red6: Change hostname as described above
2. master: ansible-playbook install_slurm.yml --limit red6
3. red6: sudo mkdir -p /var/spool/slurmctld /var/spool/slurmd /var/log/slurm
4. red6: sudo chown slurm: /var/spool/slurmctld /var/spool/slurmd /var/log/slurm
(/etc/slurm already existed)
5. master: ansible-playbook copy_slurm_config.yml –limit red6
Error: fatal: [red6]: FAILED! => {"changed": false, "msg": "Unable to start service slurmd: Job for slurmd.service failed because the control process exited with error code.\nSee \"systemctl status slurmd.service\" and \"journalctl -xeu slurmd.service\" for details.\n"}
Solution : Add in file /etc/slurm/slurm.conf on NodeName field the red6
6. master: sudo ansible-playbook copy_db_slurm_config.yml –limit red6
7. master: sudo systemctl restart slurmdbd και slurmctld
8. master: sinfo -> Check that everything works as expected
### Slurm setup (small specification so we synchronize the clocks of clients with master node)
1. Install chrony instead of NTP in every node for time synchronization
```bash
sudo apt update
sudo apt install chrony
```
2. Edited the `/etc/chrony/chrony.conf` file and added these lines:
In hpc_master:
```bash
allow 192.168.2.0/24

# Default Ubuntu NTP servers are okay
server ntp.ubuntu.com iburst

local stratum 10
```
In worker nodes first comment out every line starting with `pool` or `server` and then:
```bash
# Use master Pi as NTP server
server 192.168.2.117 iburst
```
3. In every node restart and enable the chrony service (first for hpc_master):
```bash
systemctl restart chrony
systemctl enable chrony
```
4. Run `chronyc sources`, you should get the below results:

In hpc_master:
![Screenshot from 2025-04-09 17-49-46](https://github.com/user-attachments/assets/8fbb0299-b3a3-4e4c-9dc1-1bf6f809df82)

In worker nodes:
![Screenshot from 2025-04-09 17-49-32](https://github.com/user-attachments/assets/7d3ce405-c260-4d62-b129-59c6d04ecf9f)
