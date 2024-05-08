///In this header file, you can set the constants for player
#pragma mark - SOCKET CONST

///Default port
#define SOCKET_DEFAULT_PORT @554

///Default timeout
#define SOCKET_DEFAULT_TIMEOUT 10.0


#pragma mark - RTP READ CONST

///RTP parser default framerate, used before calculation
#define READ_FRAMERATE_DEFAULT 75

///RTP parser timestamps count, used for fps calculation
#define AVERAGE_TIMESTAMPS_COUNT_FOR_FPS_CALCULATE 30

///RTP parser default buffer length, used before calculation
#define READ_BUFFER_LENGTH_DEFAULT 10000

///RTP parser readed frames in buffer treshhold divider
#define READ_FRAMES_IN_BUFFER_ACCURACY 0.5

///RTP parser default framerate calculation accuracy
#define READ_FRAMERATE_CALCULATED_ACCURACY 0.1


#pragma mark - RTSP PLAYER CONST

///RTSP player empty frames timer thrashhold
#define RTSP_PLAYER_EMPTY_FRAME_TIMER_THRASHHOLD 0.2

///RTSP player empty frames count thrashhold before audio is stopped
#define RTSP_PLAYER_EMPTY_FRAME_DISABLE_AUDIO_THRASHHOLD 3

///RTSP player empty frames count thrashhold before player is stopped
#define RTSP_PLAYER_EMPTY_FRAME_STOP_PLAYER_THRASHHOLD 200

///RTSP player retry connect count thrashhold before player is failed
#define RTSP_PLAYER_RETRY_CONNECT_THRASHHOLD 10

#pragma mark - AUDIO CONST

///Audio player buffer size per frame
#define AUDIO_PLAYER_MIN_SIZE_PER_FRAME 2048

///Audio player number of buffers
#define AUDIO_PLAYER_NUMBERS_OF_BUFFERS 3
