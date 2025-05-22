---
license: cc-by-sa-4.0
library_name: nnunet
pipeline_tag: image-segmentation
---

You should cite the following paper when using the code in this repository:

Van De Vyver, Gilles, et al. "Generative augmentations for improved cardiac ultrasound segmentation using diffusion models." arXiv preprint arXiv:2502.20100 (2025).
https://arxiv.org/abs/2502.20100

To use the model, unzip `nnUNetTrainer__nnUNetPlans__2d.zip` and follow the instructions in `inference_instructions.txt`.
For more information on the model, see the documentation of nnU-Net.

This nnU-Net model is for cardiac segmentation on apical two and four chamber views.

This model is trained on an augmented version of the CAMUS dataset: S. Leclerc, E. Smistad, J. Pedrosa, A. Ostvik, et al. "Deep Learning for Segmentation using an Open Large-Scale Dataset in 2D Echocardiography" in IEEE Transactions on Medical Imaging, vol. 38, no. 9, pp. 2198-2210, Sept. 2019. doi: 10.1109/TMI.2019.2900516

Code and information about the augmentations can be found here: https://github.com/GillesVanDeVyver/EchoGAINS

This model uses the nnU-Net architecture: Isensee, F., Jaeger, P.F., Kohl, S.A.A. et al. nnU-Net: a self-configuring method for deep learning-based biomedical image segmentation. Nat Methods 18, 203–211 (2021). https://doi.org/10.1038/s41592-020-01008-z