This is intended to implement a CNN for audio classification of voice and data transmissions.

The MXNet perl API is used to classify audio files (currently 2 categories).   Results appear to be good with my simple requirements as testing post training shows 100% success rate.

The input is radio transmissions that represent human speaking or a data transmission.   Previously, I have been doing this classification with SoX voice detection function (much lower success rate).

Unlike [Gluon Audio](https://cwiki.apache.org/confluence/display/MXNET/Gluon+-+Audio) which uses librosa to extract MFCCs I am creating spectrograms (png image files) as input to the network.   I would like to use the Gluon Audio approach however it is currently dependent on librosa which is python only.   Gluon Audio mentions MXNet FFT operator on CPU as a possible future replacement for this dependency.  So hopefully this can be used at some point.

Although the the use of machine learning for my requirements is probably overkill I plan on exanding the categories/capability in the future.

It would be great if this helps anyone like the examples below helped me.  I am open to any feedback.

To create training data
-----------------------

WAV file -> [extract middle second](https://github.com/john-/xmit_mxnet/blob/master/samples/461.205_1533495682.wav) -> [https://github.com/john-/xmit_mxnet/blob/master/samples/461.205_1533495682.wav.png](generate spectrogram PNG)

I am currently using ffmpeg to generate spectrograms outside the training process:

`/usr/bin/ffmpeg -i audio.wav -lavfi showspectrumpic=s=100x50:scale=log:legend=off audio.png
st_spect `

The spectrograms should be placed in a folder structure as documented in ImageFolderDataset.

Dependencies
------------

ffmpeg


Based on these examples
-----------------------
- [Sergey Kolychev's mnist.pl](https://github.com/apache/incubator-mxnet/blob/master/perl-package/AI-MXNet/examples/gluon/mnist.pl)
- [Sergey Kolychev's Machine learning in Perl, Part3](http://blogs.perl.org/users/sergey_kolychev/2017/10/machine-learning-in-perl-part3-deep-convolutional-generative-adversarial-network.html)
- [Eryk Wdowiak's MXNet in Perl](https://www.doviak.net/pages/mxnet/mxnet_p05.shtml)